#!/home/pair/bin/jruby
require 'java'
require 'x10.jar'
require 'comm.jar'
require 'uri'
require 'net/http'

SOURCE = java.lang.Object.new
ADDRESS_CHAR = java.lang.String.new("A").charAt(0)
ADDRESS_INT = java.lang.Long.new(1).intValue
ON = com.jpeterson.x10.event.OnEvent.new(SOURCE, ADDRESS_CHAR)
OFF = com.jpeterson.x10.event.OffEvent.new(SOURCE, ADDRESS_CHAR)
  

def x10_action(command)
  address_event = com.jpeterson.x10.event.AddressEvent.new(SOURCE,ADDRESS_CHAR,ADDRESS_INT)

  cm17a = com.jpeterson.x10.module.CM17A.new
  cm17a.setPortName("/dev/ttyS0")
  cm17a.allocate
  cm17a.transmit(address_event)
  cm17a.transmit(command)
  cm17a.waitGatewayState(com.jpeterson.x10.Transmitter::QUEUE_EMPTY)
  cm17a.deallocate
end

def cruise_failing?
  url = URI.parse('http://server-name:8080/cruisecontrol/index.jsp')
  response = Net::HTTP.start(url.host, url.port) {|http|
    http.get('/cruisecontrol/index.jsp')
  }
  case response
  when Net::HTTPSuccess, Net::HTTPRedirection
    #look for <td class="data date failure"></td> with non-empty content
    match = /(<td class=".*failure">)(\s*\d.*)(<\/td>)/.match(response.body)
    return true if !match.nil?
    return false
  else
    raise "SERVER DOWN: #{response.class}"
  end
end
x10_action(ON) if cruise_failing?
x10_action(OFF) if !cruise_failing?
