#!/usr/bin/env ruby

$LOAD_PATH << '.'
require 'yaml'
require 'person'
require 'emailer'
require 'email'
require 'santa_logger'
require 'rubygems'


# Do some testing, then set this to true when ready to send
# Will cause logging output to be shushed and mails to be sent
REALLY_SENDING = true

Logger = SantaLogger.new

people_config = YAML.load_file('config/people.yml')

people = people_config['people'].map do |attrs|
  Person.new(attrs)
end


santas = people.dup.shuffle

people.each do |person|
  person.santa = santas.delete_at(rand(santas.size))
end

Logger.log "Initial Santa assignments:"
people.each do |person|
  Logger.log person.with_santa
end

# This is the nice part of Dennis's solution: if there are any invalid
# assignments, they are corrected in as few passes as possible. (I
# originally said "a single pass", but that's not true because the
# `select` that looks for someone to swap santas with is just a
# way of saying "loop through the list of people looking for a match.")
# This works because corrections are made in a way that ensures no new 
# invalid assignments are created.
Logger.log "Checking assignments for validity"
people.each do |person|
   unless person.santa.can_be_santa_of?(person)
     Logger.log "\n#{person} can't get a gift from #{person.santa}! Let's try to fix that..."
     swap_candidates = people.select {|p| person.can_swap_santas_with?(p) }
     raise "Failure! No one can swap santas with #{person}" if swap_candidates.empty?
     Logger.log "Any of these can swap santas with #{person}: #{swap_candidates}"
     swapper = swap_candidates.sample
     Logger.log "Chose #{swapper} to swap santas with #{person}"
     misplaced_santa = person.santa
     person.santa    = swapper.santa
     swapper.santa   = misplaced_santa
   end
end

people.sort! { |a,b| a.group <=> b.group }
group = people[0].group
Logger.log "\n\nFinal Santa assignments: #{group}"
people.each do |person|
  if person.group != group 
    group = person.group
    Logger.log "\n\nFinal Santa assignments: #{group}"
  end
  Logger.log person.with_santa
end

smtp_config = YAML.load_file('config/smtp.yml')
emailer     = Emailer.new(
  smtp_config['smtp_server'], 
  smtp_config['domain'], 
  smtp_config['account_address'], 
  smtp_config['account_password']
)

people.each do |person|
  message = <<-MESSAGE
 Hello #{person.santa.name.upcase},

 Here is the draw for Christmas #{Time.now.year}.
 The person you are buying for is:

 #{person.name.upcase}
 
 THIS INFORMATION HAS BEEN KEPT SECRET FROM ALL HUMANS BUT YOU.

 Can you please let Mark know that you've received this message (but not by replying to the message - don't want to spoil the surprise for him :-)

 THAT IS ALL.

 --SANTABOT 5000
 MESSAGE
  email = Email.new(person.santa.email, "Secret Santa draw for the Lessard family: #{Time.now.year}", message)
  emailer.send(email)
end
