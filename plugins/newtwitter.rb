require 'net/http'
require 'net/https'
require 'base64'
require 'oauth'

def formatRequest
	load 'config/twitter_config.rb'
	twitter_config = return_twitter_config()

	apiUrl = 'stream.twitter.com'
	apiPage = '/1.1/statuses/filter.json'
	peopleToFollow = "horse_ebooks"
	postParameters = "follow=#{peopleToFollow}"

	timeStamp = Time.new.strftime("%s")
	signingKey = twitter_config[:consumerSecret] + '&' + twitter_config[:accessTokenSecret]
	nonce = Base64.encode64(Random.new.bytes(32)).gsub!(/\W/,'')
	parameterString = "include_entities=true&oauth_consumer_key=#{twitter_config[:consumerKey]}&oauth_nonce=#{nonce}&oauth_signature_method=HMAC-SHA1&oauth_timestamp=#{timeStamp}&oauth_token=#{twitter_config[:accessToken]}&oauth_version=1.0&#{postParameters}"
	sigBaseString = "POST&#{apiUrl}#{apiPage}&#{OAuth::Helper::escape(parameterString)}"
	signature = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), signingKey, sigBaseString)
	signature = Base64.encode64(signature)
	
	headerString  = 'OAuth '
	headerString += 'oauth_consumer_key="' + OAuth::Helper::escape(twitter_config[:consumerKey]) + '", '
	headerString += 'oauth_nonce="' + OAuth::Helper::escape(nonce) + '", '
	headerString += 'oauth_signature="' + OAuth::Helper::escape(signature) + '", '
	headerString += 'oauth_signature_method="' + OAuth::Helper::escape(twitter_config[:sigMethod]) + '", '
	headerString += 'oauth_timestamp="' + OAuth::Helper::escape(timeStamp)+ '", '
	headerString += 'oauth_token="' + OAuth::Helper::escape(twitter_config[:accessToken]) + '", '
	headerString += 'oauth_version="' + OAuth::Helper::escape(twitter_config[:oauthVersion]) + '"'

	req = Net::HTTP::Post.new(apiPage)
	req.add_field('Authorization', headerString)
	req.body = postParameters

	return req
end

def makeRequest(req)
	apiUrl = 'stream.twitter.com'
	twitterApi = Net::HTTP.new(apiUrl,443)
	twitterApi.use_ssl = true
	twitterApi.verify_mode = OpenSSL::SSL::VERIFY_NONE
	twitterApi.set_debug_output($stdout)
	res = twitterApi.request(req)
	return res
end
