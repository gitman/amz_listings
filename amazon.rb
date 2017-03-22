require 'mechanize'
require 'json'
require 'uri'

class Amazon

  def initialize(base_url)
    @base_url = base_url
    @agent = Mechanize.new # http://docs.seattlerb.org/mechanize/Mechanize.html
    @agent.user_agent_alias = 'Mac Safari'
    @theListings = {}
  end

  def load_page(url)
    3.times do
      begin
        puts url
        return @agent.get url
      rescue Timeout::Error
        next
      rescue Net::HTTPNotFound
        next
      rescue Net::HTTPServiceUnavailable
        next
      rescue Exception => e
        puts e.message
        return nil
      end
    end
    puts "#{Time.now.to_s(:db)} #{url} failure!"
    return nil
  end

  def site_directories(directory_list)
    directory_list.each_with_index do |directory, i|
      puts directory
      puts @base_url + directory.attr('href')
      puts page = load_page(@base_url + directory.attr('href'))
    end
  end

  def load_product(url)
    product_page = load_page(url)
    # puts product_page.search('div#centerCol.centerColAlign')
    puts product_page.search('div.a-section.buybox-price .a-color-price').text.gsub(/(\n|\t|\r)/, ' ').gsub(/>\s*</, '><').squeeze(' ')
    inner_html_text = product_page.at('table:contains("Best Sellers Rank")').inner_html.gsub(/(\n|\t|\r)/, ' ').gsub(/>\s*</, '><').squeeze(' ')
    # inner_html_text = product_page.search('#SalesRank').inner_html.gsub(/(\n|\t|\r)/, ' ').gsub(/>\s*</, '><').squeeze(' ')
    rank = inner_html_text[/ \#(.*?) in/,1]
    puts rank
  end

  def bestsellers(bestseller_list)
    bestseller_list.each_with_index do |bestseller, i|
      # puts bestseller
      calculated_url = nil
      if bestseller.attr('href').match(@base_url)
        calculated_url = bestseller.attr('href')
      else
        calculated_url = @base_url + bestseller.attr('href')
      end
      %w(1 2 3 4 5).each do |page_no|
        paged_url = calculated_url+ '?pg=' + page_no
        page = load_page(paged_url)
        puts page.search('h1#zg_listTitle').text
        puts '------------------------------------->>>'
        # puts = page.search('div.zg_itemImmersion div div.zg_rankDiv div.zg_rankNumber')
        impressions = page.search('div.zg_itemImmersion')
        # puts impressions.search('div.zg_rankDiv')
        impressions.each do |impression|
          product = {}
          # puts impression.search('div')
          # puts impression.search('div.zg_rankDiv')
          # puts impression.search('div.zg_itemWrapper div.a-section')
          puts product[:rank] = impression.search('div.zg_rankDiv span.zg_rankNumber').text.strip
          puts product[:asin] = JSON.parse(impression.search('div.zg_itemWrapper div.a-section').attr('data-p13n-asin-metadata'))['asin'].strip
          # puts impression.search('div.zg_itemWrapper div.p13n-sc-truncate').text.strip
          puts product[:img] = { alt: impression.search('div.zg_itemWrapper div.a-section img').attr('alt').value,
                            src: impression.search('div.zg_itemWrapper div.a-section img').attr('src').value }
          url_path = impression.search('div.zg_itemWrapper a.a-link-normal').attr('href').value
          product[:link] = "https://amazon.com#{url_path[0..url_path.index(product[:asin])+(product[:asin].length-1)]}"
          load_product(product[:link])
          puts
          # exec("imgcat #{impression.search('div.zg_itemWrapper div.a-section img').attr('src')}")
          puts '----------------------------------------'
          # puts impression.search('div.zg_itemImmersion div div.zg_rankDiv div.zg_rankNumber')
          # exit(0)
        end
        puts '<<<-------------------------------------'
        exit(0)
      end
      # puts page.search('div.zg_itemImmersion div.zg_rankDiv span.zg_rankNumber')
      # puts page.search('div.zg_rankDiv')
      # puts page.search('div.a-section a-spacing-none p13n-asin')
      exit(0)
    end
  end

  def get_lists(path)
    page = load_page(@base_url + path)
    case
    when path =~ /site-directory/
      site_directories(page.search('a.a-link-normal.fsdLink.fsdDeptLink'))
    when path =~ /bestsellers/
      bestsellers(page.search('ul#zg_browseRoot ul li a'))
    else
    end
  end
end

amz = Amazon.new('https://www.amazon.com')

# page = load_page(base_url + '/gp/site-directory')

# site_directories(page.search('a.a-link-normal.fsdLink.fsdDeptLink'))


# amz.get_lists('/gp/site-directory')
amz.get_lists('/gp/bestsellers')
