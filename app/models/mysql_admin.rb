require 'rubygems'
class MysqlAdmin < ActiveRecord::Base
  def self.connect(config)
    [ :database, :username ].each do |key|
      if config[key].blank?
        raise "Check your input,please!"
      end
    end
    config[:database] = config[:database].blank? ? "localhost" : config[:database]
    config[:port] = config[:port].blank? ? 3306 : config[:port].to_i
    config[:encoding] = config[:encoding].blank? ? 'utf8' : config[:encoding]
    config[:socket] = config[:socket].blank? ? '/var/lib/mysql/mysql.sock' : config[:socket]
    mysql = mysql_connection(config)  
    mysql.execute('set character_set_results = \'utf8\';')
    return mysql
  end
 
  def self.prepare_sql(action, params = "")
    case action
    when "current_user"
      "select current_user"
    when "sql_query"
      params
    when "table_show"
      "select * from #{params}"
    when "columns_info"
      "describe #{params}"
    when "ohter_databases"
      "show databases"
    when "create_table"
      prepare_sql_for_create_table(params)
    when "alter_table", "insert_data","query", "import_data", "delete_data", "alter_data"
      MysqlAdmin.send("prepare_sql_for_#{action}", params)
    else    
        ""
    end
  end
 
  private
  def self.prepare_sql_for_insert_data(params)
    column_names = params[:id].split(':')
    column_names_insert = []
    values = []
    column_names.each_with_index do |c, idx|
      column_names_insert << column_names[idx] unless params["value_id#{idx}"].blank?
      values << params["value_id#{idx}"] unless params["value_id#{idx}"].blank?
    end
    sql = "insert into #{params[:table_name]} (#{column_names_insert.join(',')})  values "
    sql << "('#{values.join('\',\'')}')"
    sql
  end
 
  def self.prepare_sql_for_alter_table(params)
    addition2 = ""
    if params[:option2] == 'INDEX'
      addition2 = "(#{params[:addition1]})" if params[:addition2].blank?
      addition2 = "(#{params[:addition2]})" unless params[:addition2].blank?
    else
      addition2 = params[:addition2]
    end
    "alter table #{params[:table_name]} #{params[:option1]} #{params[:option2]} #{params[:addition1]} #{addition2}"
  end
 
  def self.prepare_sql_for_delete_data(params)
    column_names = params[:id].split(':')
    order_by = ""
    limit = ""
    conditions = []
    column_names.each_with_index do |name, idx|
      next if params["value_id#{idx}"].blank?
      if params["value_id#{idx}"][/>|<|like|=|between/].blank?       
        tmp = " = '" << params["value_id#{idx}"] << "'"
      else
        tmp = params["value_id#{idx}"]
      end
      conditions << "#{column_names[idx]} #{tmp}"
    end
    unless params[:order_by_column_id].blank?
      order_by = " ORDER BY #{params[:order_by_column_id]} #{params[:order_by_id]}"
    end
    unless params[:limit_id].blank?
      limit = "LIMIT #{params[:limit_id]}"
    end
    
    if conditions.blank?
      "delete from #{params[:table_name]}"
    else
      "delete from #{params[:table_name]} where  (#{conditions.join('and')}) #{order_by} #{limit}"    
    end
  end
 
  def self.prepare_sql_for_alter_data(params)
    values = []
    conditions = []
    order_by = ""
    limit = ""
    conditions = []
    column_names = params[:id].split(':')
    column_names.each_with_index do |name, idx|
      unless params["condition_id#{idx}"].blank?
        if params["condition_id#{idx}"][/>|<|like|=|between/].blank?       
          tmp = " = '" << params["condition_id#{idx}"] <<"'"
        else
          tmp = params["condition_id#{idx}"]
        end
        conditions << "#{column_names[idx]} #{tmp}"
      end
      next if params["value_id#{idx}"].blank?
      tmp = " = '" << params["value_id#{idx}"] << "'"
      values << "#{column_names[idx]} #{tmp}"
    end
    
    
    unless params[:order_by_column_id].blank?
      order_by = " ORDER BY #{params[:order_by_column_id]} #{params[:order_by_id]}"
    end
    unless params[:limit_id].blank?
      limit = "LIMIT #{params[:limit_id]}"
    end
    
    sql = "update #{params[:table_name]} set  #{values.join(',')} "
    unless conditions.blank?
      sql = sql + "where #{conditions.join(' and ')}"
    end
    sql << " #{order_by} #{limit} "
  end
 
  def self.prepare_sql_for_create_table(params)
    columns_data = []
    20.times do |n|
      next if params["column_name"+n.to_s].blank?
      primary_key = ""
      tmp = []
      ["column_name", "datatype", "length", "not_null", "auto_inc", "default_value", "primary", "foreign_key", "ref_table"].each do |key|
        tmp << (params[key+n.to_s] || "")
      end
      primary_key = "PRIMARY KEY ( #{tmp[0]} )" if tmp[6] == "1"
      raise "Please input the ref_table infomation!" if  tmp[7] == "1" && tmp[8].blank?
      foreign_key = " index( #{tmp[0]} ), FOREIGN KEY ( #{tmp[0]} ) REFERENCES  #{tmp[8]}( #{tmp[0]} ) " if tmp[7] == "1"
      
      sql_tmp = tmp[0] + " " + tmp[1]
      unless tmp[2].blank?
        sql_tmp = sql_tmp + "( " + tmp[2] + ")" + " "
      end
      unless tmp[3].blank?
        sql_tmp = sql_tmp + "NOT NULL" + " "
      end
      unless tmp[4].blank?
        sql_tmp = sql_tmp + "AUTO_INCREMENT" + " "
      end
      unless tmp[5].blank?
        sql_tmp = sql_tmp + "DEFAULT #{tmp[5]}" + " "
      end
      columns_data << sql_tmp
      columns_data << primary_key unless primary_key.blank?
      columns_data << foreign_key unless foreign_key.blank?
    end
    
    "create table #{params["table_name"]} ( " + columns_data.join(",")+")"
  end
 
  def self.prepare_sql_for_import_data(params)
   "LOAD DATA INFILE '#{params[:file_name]}' into table #{params[:table_name]} fields terminated by ','"
  end
    
  def self.prepare_sql_for_query(params)
    column_names = params[:id].split(':')
    show_columns = []
    column_conditions = []
    sql = "select "
    column_names.each_with_index do |c, idx|
      if params["check_box_id#{idx}"] == "1"
        show_columns << column_names[idx]
        next if params["option_id#{idx}"].blank?
        unless params["option_id#{idx}"][/>|<|like|=|between/].blank?
          column_conditions[idx] = params["option_id#{idx}"]
        else
          column_conditions[idx] =  " = '#{params["option_id#{idx}"]}'"
        end
      end
    end
    sql << show_columns.join(',') << " from #{params['table_name']} "
    sql << " where " unless column_conditions.compact.blank?
    column_conditions.each_with_index do |con, idx|
      next if con.blank?
      sql << column_names[idx] << " " << con << " "
      sql << "and " if idx < column_conditions.size - 1
    end
    sql << " order by #{params[:order_by_column_id]} " unless params[:order_by_column_id].blank?
    sql << " #{params[:order_by_id]}" unless params[:order_by_id].blank?
    sql << " limit #{params[:limit_id]}" unless params[:limit_id].blank?
    sql    
  end
end

