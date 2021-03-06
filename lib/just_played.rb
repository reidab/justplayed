require 'encumber'
require 'rexml/document'
require 'time'

class JustPlayed
  class ExpectationFailed < RuntimeError
  end

  def initialize(host = 'localhost')
    @gui = Encumber::GUI.new host
  end

  def reset
    @gui.command 'restoreDefaults'
  end

  def snap(station)
    @gui.press '//UITableViewCell[text="%s"]' % station
  end

  StationTag = 1
  SnapTag = 2
  TitleTag = 3
  SubtitleTag = 4
  DownloadingTag = 5
  HelpTag = 6

  def snaps
    xml = @gui.dump
    doc = REXML::Document.new xml

    xpath = '//UILabel[tag="%s"]' % TitleTag
    titles = REXML::XPath.match doc, xpath
    titles.map! {|e| e.elements['text'].text}

    xpath = '//UILabel[tag="%s"]' % SubtitleTag
    subtitles = REXML::XPath.match doc, xpath
    subtitles.map! {|e| e.elements['text'].text}

    xpath = '//UITableViewCell[tag="%s"]' % SnapTag
    links = REXML::XPath.match doc, xpath
    links.map! {|e| e.elements['accessoryType'].text.to_i == 1}

    titles.zip(subtitles, links).inject([]) do |memo, obj|
      title, subtitle, link = obj
      memo << {:title => title, :subtitle => subtitle, :link => link}
    end
  end

  def stations
    xml = @gui.dump
    doc = REXML::Document.new xml

    xpath = '//UITableViewCell[tag="%s"]' % StationTag
    titles = REXML::XPath.match doc, xpath
    titles.map {|e| e.elements['text'].text}
  end

  def stations=(list)
    plist = Tagz.tagz do
      array_ do
        list.each {|station| string_ station}
      end
    end

    @gui.command 'setTestData', :raw, 'stations', plist
  end

  def delete_station(row)
    @gui.command 'scrollToRow', 'viewXPath', '//UITableView', 'rowIndex', row
    @gui.command 'simulateSwipe', 'viewXPath', "//UITableViewCell[#{row + 1}]"
    @gui.command 'simulateTouch', 'viewXPath', '//UIRemoveControlTextButton', 'hitTest', 0
    sleep 1
  end

  def snaps=(list)
    @gui.command 'setTestData', :raw, 'snaps', JustPlayed.snap_plist(list)
  end

  def city=(city)
    @gui.command 'setTestData', 'location', city
  end

  def server
    xml = @gui.command 'getTestData', 'key', 'lookupServer'
    doc = REXML::Document.new xml

    xpath = '//string'
    tag = REXML::XPath.match(doc, xpath).first
    tag ? tag.text : ''
  end

  def server=(url)
    @gui.command 'setTestData', 'lookupServer', url
  end

  def time=(time)
    @gui.command 'setTestData', 'testTime', time
  end

  def lookup_stations
    @gui.press toolbar_buttons[:locate]
    timeout(10) {sleep 2 while downloading?}
  end

  def lookup_snaps
    @gui.press toolbar_buttons[:lookup]
    timeout(10) {sleep 2 while downloading?}
  end

  def downloading?
    xml = @gui.dump
    doc = REXML::Document.new xml

    xpath = '//UIActivityIndicatorView[tag="%s"]' % DownloadingTag
    !REXML::XPath.match(doc, xpath).empty?
  end

  def dismiss_warning
    xml = @gui.dump
    doc = REXML::Document.new xml

    xpath = '//UIAlertView'
    warning = REXML::XPath.match(doc, xpath).first
    raise ExpectationFailed unless warning

    @gui.press '//UIThreePartButton'
  end

  def has_help_button?
    xml = @gui.dump
    doc = REXML::Document.new xml

    xpath = '//UIButton[tag="%s"]' % HelpTag
    !REXML::XPath.match(doc, xpath).empty?
  end

  def toolbar_buttons
    xml = @gui.dump
    doc = REXML::Document.new xml

    xpath = '//UIToolbarButton'
    buttons = REXML::XPath.match doc, xpath

    locations = []
    buttons.each_with_index do |b, i|
      locations << [b.elements['frame/x'].text.to_f, i + 1]
    end
    locations.sort!

    {:locate => "//UIToolbarButton[#{locations[0][1]}]",
     :lookup => "//UIToolbarButton[#{locations[1][1]}]",
     :delete_all => "//UIToolbarButton[#{locations[2][1]}]"}
  end

  def restart
    begin
      @gui.command 'terminateApp'
    rescue EOFError
      # no-op
    end

    sleep 3

    yield if block_given?

    system(<<-HERE)
      osascript -e 'tell application "Xcode"'\\
        -e 'set myProject to active project document'\\
        -e 'launch the active executable of myProject'\\
      -e 'end tell' >/dev/null
    HERE

    sleep 7
  end

  def delete_all
    @gui.press toolbar_buttons[:delete_all]
  end

  def answer(accept)
    index = accept ? 1 : 2
    @gui.press "//UIThreePartButton[#{index}]"
  end

  def JustPlayed.snap_plist(snaps)
    Tagz.tagz do
      array_ do
        snaps.each do |snap|
          dict_ do
            key_ 'title'
            string_ snap[:title]
            key_ 'subtitle'
            string_ snap[:subtitle]
            key_ 'needsLookup'
            tagz__ snap[:link] ? 'false/' : 'true/'

            if (snap[:created_at])
              key_ 'createdAt'
              date_ snap[:created_at].utc.iso8601
            end
          end
        end
      end
    end
  end
end
