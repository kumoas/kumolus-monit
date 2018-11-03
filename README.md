Kumolus Monit Rubygem
=============

A Ruby interface for Monit.

## Installation

Just like any other gem:

    gem install kumolus-monit

## Usage

    status = Monit::Status.new({ :host => "monit.myserver.com",
                                 :path => "/monitor",
                                 :port => 433,
                                 :auth => true,
                                 :username => "foo",
                                 :password => "bar" })
    status.get              # => true
    status.platform         # => <Monit::Platform:0x00000003673dd0 ... >
    status.platform.cpu     # => 2
    status.platform.memory  # => 4057712

    # => start/stop/restart/monitor/unmonitor
    status.services.each do |service|
      service.stop!
    end