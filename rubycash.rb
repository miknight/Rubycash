#!/usr/bin/env ruby

require 'yaml'
require 'rubygems'
require 'bundler/setup'
require 'mechanize'

class Rubycash

	def initialize(username, password, user_agent_alias='Mac Safari')
		@username = username
		@password = password
		@agent = Mechanize.new()
		@agent.user_agent_alias = user_agent_alias
	end

	def log(msg)
		puts msg
	end

	def fetchPage(url, msg)
		if url !~ /^https?:\/\//
			url = @base_url + url
		end
		wait = 2
		begin
			log(msg)
			page = @agent.get(url)
		rescue Exception => e
			seconds = wait ** wait # This gives intervals of ~ 4 seconds, 27 seconds and 4 mins
			log("Failed with exception '#{e}', retrying after #{seconds} seconds...")
			sleep(seconds)
			wait += 1
			retry unless wait > 4
			return false
		end
		return page
	end

	def findButton(form, name=nil)
		return nil if name.nil?
		form.buttons.each do |button|
			name_esc = Regexp.escape(name)
			return button if button.name =~ /#{name_esc}/
		end
		log("Could not find button #{name}.")
		return nil
	end

	def setMatchField(form, name, value)
		form.fields.each do |field|
			name_esc = Regexp.escape(name)
			if field.name =~ /#{name_esc}/
				form[field.name] = value
			end
		end
	end

	def submitForm(form, msg, button=nil)
		log(msg)
		result = @agent.submit(form, findButton(form, button))
		return result;
	end

	def login()
		page = fetchPage('/SignIn.aspx', 'Getting login page...')
		form = page.forms.first
		if form.nil?
			raise "Cannot find form."
		end
		setMatchField(form, '$mainContent$txtEmail', @username)
		setMatchField(form, '$mainContent$txtPassword', @password)
		result = submitForm(form, "Submitting login form (as #{@username})...", '$mainContent$btnSignIn')
		if result.body !~ /account\/settings.aspx/
			raise "Login failed."
		end
	end

	def doDailyRun()
		raise notImplementedError
	end

	def self.run()
		config = YAML::load_file(File.dirname(__FILE__) + '/config.yml')
		config['accounts'].each do |user|
			my_site = self.new(user['username'], user['password'])
			begin
			  my_site.doDailyRun()
			rescue Exception => e
			  puts e
			  print e.backtrace.join("\n")
		  end
		end
	end

end
