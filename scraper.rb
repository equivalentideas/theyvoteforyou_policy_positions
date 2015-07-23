require 'scraperwiki'
require 'mechanize'
require 'rest-client'
require 'json'

# get all the policies through the They Vote For You API 
api_data = RestClient.get "https://theyvoteforyou.org.au/api/v1/policies.json?key=#{ENV['MORPH_MY_TVFY_KEY']}"
policies = JSON.parse(api_data)

policies.each do |policy_data|
  # Get the basic meta data from the API JSON
  policy = {
    name: policy_data['name'],
    id: policy_data['id'],
    datetime_scraped: DateTime.now.to_s,
    scrape_id: (policy_data['id'].to_s + '_' + Date.today.to_s.gsub('-','')).to_s,
    provisional: policy_data['provisional'].to_s
  }

  # get the policy page for scraping
  agent = Mechanize.new
  page = agent.get("https://theyvoteforyou.org.au/policies/#{policy_data['id']}")

  # scrape the count for each position in the policy
  page.search('.policy-comparision-block').each do |position|
    policy[position.at('h3').attr('id').gsub('-','_').to_sym] = position.search('.member-item').count
  end

  # scrape the division count
  policy['division_count'] = page.search('.division-title').count

  # Write out to the sqlite database using scraperwiki library
  p policy # for debugging, this should be too massive
  ScraperWiki.save_sqlite([:scrape_id], policy)
end
