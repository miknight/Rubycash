#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/rubycash'

class RewardsCentral < Rubycash

	def initialize(username, password)
		@base_url = "http://www.rewardscentral.com.au"
		super(username, password)
	end

	def doQuickQuiz()
		page = fetchPage('/earn/QuickSurvey.aspx', 'Getting Quick Quiz page...')
		form = page.forms.first
		if page.body =~ /You have already/
			log('Quiz already completed.')
			return
		end
		type = form.radiobuttons
		if type == []
			type = form.checkboxes
		end
		if !type.last.nil?
			type.last.check
		end
		# if there are no radios or checkboxes, there's probably no question for today
		result = submitForm(form, 'Submitting Quick Quiz form...', 'ctl00$mainContent$QuickSurvey1$btnSubmit')
		if result.body =~ /Thank you for your answer/
			log('Quiz completed successfully!')
		else
			log('Unable to verify if Quiz completed succesfully.')
		end
	end

	def doWebClick()
		page = fetchPage('/earn/WebClicks.aspx', 'Getting Web Clicks page...')
		if page.body =~ /You have already/
			log('Web Click already completed.')
			return
		end
		links = scrapeLinks(page)
		link = links[rand(links.size)]
		puts "Clicking web link: #{link.href}"
		visitTrackedLink(link)
	end

	def doBonusClicks()
		page = fetchPage('/earn/webClicksBonus.aspx', 'Getting Bonus Clicks page...')
		links = scrapeLinks(page)
		links.each do |link|
			puts "Clicking bonus link: #{link.href}"
			visitTrackedLink(link)
		end
	end

	def scrapeLinks(page)
		links = []
		page.links.each do |link|
			if link.href =~ /TopFrame.aspx\?adid=\d+/
				links.push(link)
			end
		end
		return links
	end

	def visitTrackedLink(link)
		result = link.click
		# `result' is now an iframe
		real_links = result.body.scan(/src="(.+?)"/).flatten;
		real_click = real_links[0]
		# This page is the top iframe that counts down from 10 and then reloads.
		# Wait 10 seconds before we phone home (8 is really enough though).
		wait = 8
		page = fetchPage('/earn/' + real_click, "Waiting #{wait} seconds...")
		sleep(wait)
		return fetchPage('/earn/' + real_click, 'Reporting link has been clicked...')
	end

	def doGuessingGame()
		page = fetchPage('/community/GuessingGame.aspx', 'Getting Guessing Game page...')
		form = page.forms.first
		gg_button = 'ctl00$mainContent$btnSubmitGuessing'
		# has the field already been filled in?
		if page.body =~ /disabled/
			log('Guessing Game already completed.')
			return
		end
		# generate seven numbers between 1 to 10,000
		numbers = []
		7.times { numbers.push(1 + rand(9999)) }
		# load numbers into form
		num_loaded = 0;
		for i in (0..6)
			field_name = 'ctl00$mainContent$txtguess' + (i+1).to_s
			# They might have 5, 6 or 7 fields to fill in, depending on Experience Points
			if form.has_field?(field_name)
				form[field_name] = numbers[i]
				num_loaded += 1
			end
		end
		# submit our values and check the result
		result = submitForm(form, "Submitting #{num_loaded} numbers...", gg_button)
		if result.body =~ /Your guessing game entry has been accepted/
			log('Guessing Game completed successfully!')
		else
			log('Unable to verify if Guessing Game completed succesfully.')
		end
	end

	def doRewardMail()
		base = '/Earn/'
		page = fetchPage(base + 'RewardMail.aspx', 'Getting Reward Mail page...')
		rlinks = []
		# look for the links to the Reward Mail emails
		page.links.each do |link|
			if link.href =~ /(ReadRewardMail.aspx\?uid=[\w-]+&aid=[\w-]+)/i
				rlinks.push($1)
			end
		end
		# look for the rows that are unread
		rows = page.body.scan(/<tr>.+?<strong>[^<]+<\/strong>.+?<\/tr>/im)
		rows.each do |row|
			# find which links are for unread Reward Mail only
			rlinks.each do |link|
				readRewardMail(base + link) if row.index(link)
			end
		end
	end

	def readRewardMail(path)
		# fetch the Reward Mail
		page = fetchPage(path, 'Visiting Reward Mail at ' + @base_url + path)
		elinks = []
		# find the link that will earn us points
		page.links.each do |link|
			if link.href =~ /(\/Earn\/to.aspx\?uid=[\w-]+&aid=[\w-]+.*&rtype=1)/i
				fetchPage($1, 'Clicking Reward Mail points link: ' + link.href)
				break
			end
		end
	end

	def doDailyRun()
		login()
		doQuickQuiz()
		doGuessingGame()
		doRewardMail()
		doWebClick()
		doBonusClicks()
	end

end

if $PROGRAM_NAME == __FILE__
	RewardsCentral::run()
end
