module WebsiteOptimizerHelper

  mattr_accessor :account_id
  
  def self.included(base)
    require_account_id
  end  

  def gwo_multivariate(tracker_id, description, &block)
    multivariate_controll_script(tracker_id)
    multivariate_tracking_script(tracker_id)
    multivariate_section_script(description, &block)
  end

  # Control/Tracking Script for A/B control page
  #
  def gwo_ab_control(tracker_id)
    ab_controll_script(tracker_id)
    ab_tracking_script(tracker_id)
  end

  # Tracking Script for A/B variation pages
  #
  def gwo_ab_variation(tracker_id)
    ab_tracking_script(tracker_id)
  end

  # Conversion Script: Will be included at the end of the conversion
  # page's source code
  #
  def gwo_conversion_script(tracker_id)
    google_analytics_tracking_script(tracker_id, "/#{tracker_id}/goal")
  end


  private


  def require_account_id
    raise "You must set a Google Website Optimizer Account ID" if WebsiteOptimizerHelper.account_id.blank?
  end

  def multivariate_section_script(description, &block)
    if block_given?
      content = capture(&block)
      concat(content_tag('script', "utmx_section(\"#{description}\")"), block.binding)
      concat(content, block.binding)
      concat("</noscript>", block.binding)
    else
      raise(ArgumentError, "No block provided")
    end
  end

  def multivariate_tracking_script(tracker_id)
    google_analytics_tracking_script(tracker_id, "/#{tracker_id}/test")
  end

  def multivariate_controll_script(tracker_id)
    content_for(:head) { content_tag('script', "function utmx_section(){}function utmx(){}(function(){var k='#{tracker_id}',d=document,l=d.location,c=d.cookie;function f(n){if(c){var i=c.indexOf(n+'=');if(i>-1){var j=c.indexOf(';',i);return c.substring(i+n.length+1,j<0?c.length:j)}}}var x=f('__utmx'),xx=f('__utmxx'),h=l.hash;d.write('<sc'+'ript src=\"'+'http'+(l.protocol=='https:'?'s://ssl':'://www')+'.google-analytics.com'+'/siteopt.js?v=1&utmxkey='+k+'&utmx='+(x?x:'')+'&utmxx='+(xx?xx:'')+'&utmxtime='+new Date().valueOf()+(h?'&utmxhash='+escape(h.substr(1)):'')+'\" type=\"text/javascript\" charset=\"utf-8\"></sc'+'ript>')})();") }
  end

  def ab_controll_script(tracker_id)
    multivariate_controll_script(tracker_id)
    content_for(:head) { content_tag('script', "utmx(\"url\",'A/B');") }
  end

  def ab_tracking_script(tracker_id)
    google_analytics_tracking_script(tracker_id, "/#{tracker_id}/test")
  end

  # Assumes using Google Analytics with ga.js
  #
  def ga_tracking_script(tracker_id, tracker)
    tracker_name = 'websiteOptimizerTracker' + tracker_id
    content = "var #{tracker_name} = _gat._getTracker(\"#{account_id}\");"
    content << "#{tracker_name}._initData();"
    content << "#{tracker_name}._trackPageView(\"#{tracker}\");"
    content_for(:website_optimizer_tracking) { content_tag('script', content, :type => "text/javascript") }
  end
  alias google_analytics_tracking_script ga_tracking_script if RAILS_ENV == 'production'

  # For use with validating pages when setting up experiment
  #
  def urchin_tracking_script(tracker_id, tracker)
    urchin = content_tag('script', "if(typeof(urchinTracker)!='function')document.write('<sc'+'ript src=\"'+'http'+(document.location.protocol=='https:'?'s://ssl':'://www')+'.google-analytics.com/urchin.js'+'\"></sc'+'ript>')")
    tracker = content_tag('script', "try {_uacct = '#{account_id}';urchinTracker(\"#{tracker}\");} catch (err) { }")
    content_for(:website_optimizer_tracking) { urchin + tracker }
  end
  alias google_analytics_tracking_script urchin_tracking_script if RAILS_ENV == 'development'

end
