require 'net/http'
require 'net/https'
require 'base64'
require 'cgi'
require 'oauth'

def makeRequest
	oauth = Hash.new
	load 'config/twitter_config.rb'
	apiUrl = 'stream.twitter.com'
	apiPage = '/1.1/statuses/filter.json'
	peopleToFollow = "horse_ebooks"
	postParameters = "follow=#{peopleToFollow}"
	timeStamp = Time.new.strftime("%s")
	signingKey = twitter_config[:consumerSecret] + '&' + twitter_config[:accessTokenSecret]
	nonce = Base64.encode64(Random.new.bytes(32)).gsub!(/\W/,'')
	parameterString = "include_entities=true&oauth_consumer_key=#{twitter_config[:consumerKey]}&oauth_nonce=#{nonce}&oauth_signature_method=HMAC-SHA1&oauth_timestamp=#{timeStamp}&oauth_token=#{twitter_config[:accessToken]}&oauth_version=1.0&#{postParameters}"
	sigBaseString = "POST&#{apiUrl}#{apiPage}&#{CGI.escape(parameterString)}"
	signature = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), signingKey, sigBaseString)
	signature = Base64.encode64(signature)
	
	twitterApi = Net::HTTP.new(apiUrl,443)
	twitterApi.use_ssl = true
	twitterApi.verify_mode = OpenSSL::SSL::VERIFY_NONE
	
	oauth['oauth_consumer_key'] = twitter_config[:consumerKey]
	oauth['oauth_nonce'] = nonce
	oauth['oauth_signature'] = signature
	oauth['oauth_signature_method'] = twitter_config[:sigMethod]
	oauth['oauth_timestamp'] = timeStamp
	oauth['oauth_token'] = twitter_config[:accessToken]
	oauth['oauth_version'] = twitter_config[:oauthVersion]
	headerString = "OAuth "
	# this doesn't do it in order
	oauth.each do |key,val|
		headerString += OAuth::Helper::escape(key) + '="' + OAuth::Helper::escape(val) + '", '
	end
	headerString = headerString[0..-2]
	headers = { 'Authorization' => headerString }
	twitterApi.post(apiPage,postParameters,headers)
end

makeRequest()
