# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def loading_view
    "Now Loading............"
  end
  
  def nbsp_in_blank(var)
    if var.blank?
      return '&nbsp;'
    else
      return var
    end
  end
  
  def pagination_links_for_list_with_ajax(paginator, options = {})
    div_tag = lambda{|content| content_tag(:div, content, :class => 'paginationLinksArea') }
    
    return div_tag.call('Page: Not Found') if paginator[:item_count] == 0
    
    #default
    options[:loading] ||= "Element.update('#{options[:update]}', 'Now Loading')"
    
    result = <<-EOM

<div>
Item: #{paginator[:current_first_number]} - 
#{paginator[:current_last_number]} in #{paginator[:item_count]} items &nbsp;&nbsp;</div>
<div>Page: 
    EOM
    
    if paginator[:current_page] > 1
      result << link_to_remote('Previous', options.merge(:url => options[:url].merge( {:page => (paginator[:current_page] - 1)} ))) << "&nbsp;"
    end
    
    links = my_pagination_links_each(paginator, {:window_size => 10}) do |i|
      link_to_remote("#{i}", options.merge( :url => options[:url].merge({:page => i})))
    end
    
    result << links if links
    if paginator[:current_page] < paginator[:page_count]
      result << ' '
      result << link_to_remote('Next', options.merge( :url => options[:url].merge(:page => (paginator[:current_page] + 1))))
    end
    result << '</div>'

    div_tag.call(result)
  end
  
  def my_pagination_links_each(paginator, options)
    
    first = [1, (paginator[:current_page] - options[:window_size])].max
    last = [paginator[:page_count], (paginator[:current_page] + options[:window_size])].min
    
    html = ''
    if first > 1
      html << yield(1)
      html << ' ... ' if first > 2
    end
    html << ' '
    
    (first..last).each do |i|
      if paginator[:current_page] == i
        html << i.to_s
      else
        html << yield(i)
      end
      html << ' '
    end

    if last < paginator[:page_count]
      html << ' ... ' if last < paginator[:page_count] - 1
      html << yield(paginator[:page_count])
    end
    
    html
  end
end
