# this is a BLUNT instrument to unintelligently stop a DDOS
# USAGE: config.middleware.use "BluntForceTrauma"

class BluntForceTrauma

  def initialize(app)
    @app = app

    @dirt_nap_duration = 2.hours
    @max_requests_before_blunt_force_trauma = 70


    # render blank response
    @response = [403, {'Content-Type' => (options[:content_type] || 'text/html')}, [""]]
  end

  def self.resuscitate(specific_ip = nil)
    return Rails.cache.delete("ip_#{specific_ip}") if !specific_ip.blank?
    Rails.cache.read("blunt_force_trauma").each do |banned_ip|
      Rails.cache.delete("ip_#{banned_ip}")
    end
  end

  def call(env)
    remote_addr = env['REMOTE_ADDR']

    cache_key = "ip_#{remote_addr}"
    if !Rails.cache.read(cache_key, :raw => true).blank?
      _val = Rails.cache.read(cache_key, :raw => true).to_i
      Rails.cache.write(cache_key, (_val+1).to_s, :raw => true)
    else
      Rails.cache.write(cache_key, "1", :expires_in => @dirt_nap_duration, :raw => true)
    end

    if Rails.cache.read(cache_key).to_i > @max_requests_before_blunt_force_trauma

      if Rails.cache.read("blunt_force_trauma")
        _banned_ips = Rails.cache.read("blunt_force_trauma").clone
        unless _banned_ips.include?(remote_addr)
          _banned_ips = _banned_ips + [remote_addr]
          Rails.cache.write("blunt_force_trauma", _banned_ips)
        end
      else
        Rails.cache.write("blunt_force_trauma", [remote_addr])
      end
      return @response
    end

    @app.call(env)
  end

end
