#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/rubycash'

class MyOpinions < Rubycash

	def initialize(username, password)
		@base_url = "http://www.myopinions.com.au"
		super(username, password)
	end

	def doQuickSurvey()
		page = fetchPage('/', 'Getting Home Page to check for Quick Surveys...')
		if page.body =~ /You have (\d+) Quick Surveys available/ and $1.to_i > 0
			log("There are #{$1} Quick Surveys left to do.")
		else
			log('All Quick Surveys have been completed.')
			return false
		end
		form = page.forms.first
		type = form.radiobuttons
		if type == []
			type = form.checkboxes
		end
		if !type.last.nil?
			type.last.check
		end
		# If there are no radios or checkboxes, there's probably no question for today.
		result = submitForm(form, 'Submitting Quick Quiz form...', 'm$mainContent$QuickSurvey1$btnSubmit')
		if result.body =~ /Thank you for your answer/
			log('Quiz completed successfully!')
		else
			log('Unable to verify if Quiz completed succesfully.')
		end
		return true
	end

	def doInstantWin()
		page = fetchPage('/rewards/instantwin.aspx', 'Getting Instant Win page...')
		if page.body =~ /You have already played/
			log('Instant Win already completed.')
			return
		end
		form = page.forms.first
		row = rand(7) + 1;
		col = rand(7) + 1;
		form['__EVENTTARGET'] = "m$mainContent$rptBoxRow$ctl0#{row}$rptBoxCol$ctl0#{col}$clk";
		result = submitForm(form, 'Submitting Instant Win form...')
		if result.body =~ /Congratulations! You won (\d+) points!/
			log("Instant Win yielded #{$1} points.")
		else
			log("Instant Win yielded no points.")
		end
	end

	def doDailyRun()
		login()
		while doQuickSurvey()
			# Nothing to do.
		end
		doInstantWin()
	end

end

if $PROGRAM_NAME == __FILE__
	MyOpinions::run()
end
