class AppDelegate < PM::Delegate
  def on_load(app, options)
    open ItemsScreen.new(
      nav_bar: true,
      feed_url: 'http://headlines.yahoo.co.jp/rss/all-c_sci.xml'
    )
  end
end

class ItemsScreen < PM::TableScreen
  attr_accessor :feed_url
  title "RssProMotion"
  refreshable callback: :on_refresh,
    pull_message: "Pull to refresh",
  refreshing: "Refreshing data..."

  def fetch_feed
    BW::HTTP.get(self.feed_url) do |res|
      items = []
      if res.ok?
        BW::RSSParser.new(res.body.to_str, true).parse do |item|
          items.push(item)
        end
      else
        App.alert(res.error_message)
      end

      @items = [{
        cells: items.map do |item|
          {
            title: item.title,
            action: :tapped_item,
            arguments: item,
          }
        end
      }]
      end_refreshing
      update_table_data
    end
  end

  def on_load
    fetch_feed
  end

  def on_refresh
    fetch_feed
  end

  def table_data
    @items ||= []
  end

  def tapped_item(item)
    open WebScreen.new(url: item.link, title: item.title)
  end
end

class WebScreen < PM::WebScreen
  attr_accessor :url

  def on_load
    @indicator ||= add UIActivityIndicatorView.gray, {
      center: [view.frame.size.width / 2, view.frame.size.height / 2 - 42]
    }
  end

  def content
    self.url.nsurl
  end

  def load_started
    @indicator.startAnimating
  end

  def load_finished
    @indicator.stopAnimating
  end
end
