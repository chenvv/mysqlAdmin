class MainController < ApplicationController
  PER_PAGE = 20
  before_filter :check_permission, :except => :top
 
  def top
    if request.post?
      begin
        session['user'] = params
        @conn = MysqlAdmin.connect(params)
      rescue => ex
        @error_message = ex
      end

      if @conn
        redirect_to :action => 'index'
      end
    end
  end

  def index
    begin
      @database = @conn.current_database
      @table_nms = @conn.tables
      @current_user = execute("current_user").fetch_row[0]
      @native_database_types = @conn.native_database_types
      @conn.disconnect!
    rescue => ex
      @error_message = ex
      session['user'] = nil
      redirect_to :action => 'top'
    end
  end

  def get_table_name_list
    begin
      @table_nms = @conn.tables
      render :partial => "table_name_list"
    rescue
      render :text => "Failed!"
    end
  end

  def table_title
    render :partial => "table_title"
  end
 
  def table_show
    begin
      @table_nm = params[:table_nm]
      get_columns_info
      if request.get?
        current_page = 1
      else
        current_page = params[:page].to_i
      end
      
      get_result_pages("table_show", params[:table_nm], current_page)
      render :partial =>'result_show', :locals => {:action => "table_show", :query_sql => params[:query_sql]}
      
      @conn.disconnect!
    rescue => ex
      @error_message = ex
      render :partial => 'error_message'
    end
  end
 
  def get_columns_info
    columns = execute("columns_info", params[:table_nm])
    @table_header1 = []
    @table_header2 = []
    columns.each  do |re|
      if re.include?("PRI")
        @table_header1 << "#{re[0]}(PRI)"
      else
        @table_header1 << "#{re[0]}"
      end
      @table_header2 << re[1]
    end
  end
 
  def get_result_pages(action, params, current_page)
    @result_pages = {}
    @table_contents = []
    tmp_result = execute(action, params)
    per_page = (session['per_page'] || PER_PAGE).to_i
    @result_pages[:item_count] = tmp_result.num_rows
    @result_pages[:current_first_number] = per_page * (current_page - 1) + 1
    @result_pages[:current_last_number] = [per_page * current_page, @result_pages[:item_count]].min
    @result_pages[:page_count] = @result_pages[:item_count] / PER_PAGE + 1
    @result_pages[:current_page] = current_page
    tmp_result.data_seek(per_page * (current_page - 1))
    per_page.times do |t|
      if row = tmp_result.fetch_row
        @table_contents << row
      end
    end
    @table_header1 = tmp_result.fetch_fields().map{|f| f.name}
    @params_for_paginate = @params_for_paginate || {}
  end

  def create_table_show
    render :partial => "create_table_show", :locals => {:line_no => 1}
  end

  def sql_query_show
    render :partial => 'sql_query'
  end

  def sql_query
    unless params[:query_sql].blank?
      begin
        if request.get?
          current_page = 1
        else
          current_page = params[:page].to_i
        end
        get_result_pages("sql_query", params[:query_sql], current_page)
        render :partial =>'result_show', :locals => {:action => "sql_query", :query_sql => params[:query_sql]}
      rescue => ex
        @error_message = ex
        render :partial => 'error_message'
      end
    else
      render :text => '<div style="font: 12px;color:#FF4500">Please check your input!</div>'
    end
  end

  def query_show
    begin
      @table_nms = @conn.tables
      render :partial => 'query_show'
    rescue => ex
      @error_message = ex
      render :partial => 'error_message'
    end
  end

  def other_databases_show
    begin
      result = execute("ohter_databases")  
      @other_databases = []
      result.each do |row|
        @other_databases << row[0] if row[0] != current_database
      end
      @conn.disconnect!
      render :partial => 'other_databases'
    rescue
      render :text => 'Failed!'
    end
  end
 
  def change_database
    begin
      @conn.disconnect!
      session['user']['database'] = params[:other_database]
      check_permission
      redirect_to :action => 'index'
    rescue
      render :text => 'Failed!'
    end
  end
 
  def current_database
    @conn.current_database
  end
 
  def get_columns_for_table
    if params[:table_name].blank?
      @error_message = "No table name error!"
      render :partial => 'error_message'
    else
      begin
        @column_names = get_columns
        render :partial => "columns_show"
      rescue
        @error_message = "Your have input a wrong table name!"
        render :partial => 'error_message'
      end
    end
  end
 
  def get_columns_for_table_to_insert
    begin
      @column_names = get_columns
      render :partial => "columns_for_insert"
    rescue => ex
      @error_message = ex.message
      render :partial => 'error_message'
    end
  end
 
  def get_columns_for_table_to_alter
    begin
      @column_names = get_columns
      render :partial => "columns_for_alter"
    rescue
      @error_message = "Your have input a wrong table name!"
      render :partial => 'error_message'
    end
  end
 
  def get_columns_for_table_to_delete
    begin
      @column_names = get_columns
      render :partial => "columns_for_delete"
    rescue
      @error_message = "Your have input a wrong table name!"
      render :partial => 'error_message'
    end
  end    
   
  def get_columns
    result = execute("columns_info", params[:table_name])
    column_names = []
    result.each  do |re|
      column_names << "#{re[0]}"
    end
    column_names
  end

  def query
    begin
      @table_contents = execute("query", params)
      @table_header1 = @table_contents.fetch_fields().map{|f| f.name}
      if request.get?
        current_page = 1
      else
        current_page = params[:page].to_i
      end
      get_result_pages("query", params, current_page)
      render :partial =>'result_show', :locals => {:action => "query", :query_sql => "" }
    rescue
      @error_message = "Please check your input!"
      render :partial => 'error_message'
    end
  end
 
  def create_table
    begin
      raise 'Please input table name! <br/>' if params[:table_name].blank?
      execute("create_table", params)
      @conn.disconnect!
      render :text=>"Table Create Successful!"
    rescue => ex
      @error_message = ex.message
      render :partial => 'error_message'
    end
  end

  def drop_table
    if request.post?
      begin
        @conn.drop_table(params[:table_name])
        render :text=>"Table Drop Successful!" if @error_message.blank?
      rescue
        @error_message = "There's something wrong!"
        render :partial => "drop_table"
      end
    else
      @table_nms_option = @conn.tables
      render :partial => "drop_table"
    end
  end

  def alter_table_show
    @table_nms_option = @conn.tables
    render :partial => 'alter_table_show'  
  end

  def alter_table
    begin
      @result = execute("alter_table", params)
    rescue => ex
      @error_message = ex.message
      render :partial => 'error_message'
    end
    render :text=>"Table Alter Successful!" if @error_message.blank?
  end

  def insert_data_show
    @table_nms_option = @conn.tables
    render :partial => 'insert_data_show'  
  end
 
  def insert_data
    begin    
      @column_names = get_columns
      raise "Please check your input!" unless params.keys.detect {|a| !a["value_id"].blank? && (!params[a].blank?) }
      execute("insert_data", params)
      render :text=>"Table Insert Data Successful!"
    rescue => ex
      @error_message = ex.message
      render :partial => 'error_message'
    end
  end
 
 def delete_data_show
    @table_nms_option = @conn.tables
    render :partial => 'delete_data_show'  
  end
 
  def delete_data
    begin
      execute("delete_data", params)
      @conn.disconnect!
      render :text=>"Table Delete Data Successful!"
    rescue => ex
      @error_message = ex.message
      render :partial => 'error_message'
    end
  end
 
 def alter_data_show
    @table_nms_option = @conn.tables
    render :partial => 'alter_data_show'  
  end
 
  def alter_data
    begin
      execute("alter_data", params)
      render :text=>"Table Delete Data Successful!"
    rescue => ex
      @error_message = ex.message
      render :partial => 'error_message'
    end
  end
 
  def import_data_show
    @table_nms_option = @conn.tables
    render :partial => 'import_data_show'  
  end
 
  def import_data
    begin
      execute("import_data", params)
      render :text=>"Data import Successful!"
    rescue => ex
      @error_message = ex.message
      render :partial => 'error_message'
    end    
  end
 
  def log_out
    begin
      @conn.disconnect! if @conn
    rescue
    ensure
      @conn = nil
      session['user'] = nil
    end
    redirect_to :action=> 'top'
  end
 
  def execute(action, params = "")
    sql = MysqlAdmin.prepare_sql(action, params)
    @conn.execute(sql)
  end
 
  private
  def check_permission
    if session['user'].blank?
      redirect_to :action =>'top' if session['user'].blank?
      return
    end
    
    begin
      @conn = MysqlAdmin.connect(session['user']) unless @conn
    rescue
      redirect_to :action =>'top'
    end
  end
end
