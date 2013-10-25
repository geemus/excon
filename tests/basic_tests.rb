Shindo.tests('Excon basics') do
  with_rackup('basic.ru') do
    basic_tests

    connection = Excon::Connection.new({
      :host             => '127.0.0.1',
      :nonblock         => false,
      :port             => 9292,
      :scheme           => 'http',
      :ssl_verify_peer  => false
    })
    tests('explicit uri passed to connection') do
      tests('GET /content-length/100').returns(200) do
        response = connection.request(:method => :get, :path => '/content-length/100')
        response[:status]
      end
    end
    expected_formatted_uri = 'http://127.0.0.1:9292/content-length/100'
    tests('unix socket formatted_uri').returns(expected_formatted_uri) do
      params = connection.data.merge(:method => :get, :path => '/content-length/100')
      Excon::Utils.formatted_uri(params)
    end
  end
end

Shindo.tests('Excon basics (Basic Auth Pass)') do
  with_rackup('basic_auth.ru') do
    basic_tests('http://test_user:test_password@127.0.0.1:9292')

    tests('Excon basics (Basic Auth Fail)') do
      cases = [
        ['correct user, no password', 'http://test_user@127.0.0.1:9292'],
        ['correct user, wrong password', 'http://test_user:fake_password@127.0.0.1:9292'],
        ['wrong user, correct password', 'http://fake_user:test_password@127.0.0.1:9292'],
      ]
      cases.each do |desc,url|
        tests("response.status for #{desc}").returns(401) do
          connection = Excon.new(url)
          response = connection.request(:method => :get, :path => '/content-length/100')
          response.status
        end
      end
    end
  end
end

Shindo.tests('Excon basics (ssl)') do
  with_rackup('ssl.ru') do
    basic_tests('https://127.0.0.1:9443')
  end
end

Shindo.tests('Excon basics (ssl file)',['focus']) do
  with_rackup('ssl_verify_peer.ru') do

    tests('GET /content-length/100').raises(Excon::Errors::SocketError) do
      connection = Excon::Connection.new({
        :host             => '127.0.0.1',
        :nonblock         => false,
        :port             => 8443,
        :scheme           => 'https',
        :ssl_verify_peer  => false
      })
      connection.request(:method => :get, :path => '/content-length/100')
    end

    basic_tests('https://127.0.0.1:8443',
                :client_key => File.join(File.dirname(__FILE__), 'data', 'excon.cert.key'),
                :client_cert => File.join(File.dirname(__FILE__), 'data', 'excon.cert.crt'),
                :reset_connection => RUBY_VERSION == '1.9.2'
               )

  end
end

Shindo.tests('Excon basics (ssl file paths)',['focus']) do
  with_rackup('ssl_verify_peer.ru') do

    tests('GET /content-length/100').raises(Excon::Errors::SocketError) do
      connection = Excon::Connection.new({
        :host             => '127.0.0.1',
        :nonblock         => false,
        :port             => 8443,
        :scheme           => 'https',
        :ssl_verify_peer  => false
      })
      connection.request(:method => :get, :path => '/content-length/100')
    end

    basic_tests('https://127.0.0.1:8443',
                :private_key_path => File.join(File.dirname(__FILE__), 'data', 'excon.cert.key'),
                :certificate_path => File.join(File.dirname(__FILE__), 'data', 'excon.cert.crt')
               )

  end
end

Shindo.tests('Excon basics (ssl string)', ['focus']) do
  with_rackup('ssl_verify_peer.ru') do
    basic_tests('https://127.0.0.1:8443',
                :private_key => File.read(File.join(File.dirname(__FILE__), 'data', 'excon.cert.key')),
                :certificate => File.read(File.join(File.dirname(__FILE__), 'data', 'excon.cert.crt'))
               )
  end
end

Shindo.tests('Excon basics (Unix socket)') do
  pending if RUBY_PLATFORM == 'java' # need to find suitable server for jruby

  file_name = '/tmp/unicorn.sock'
  with_unicorn('basic.ru', file_name) do
    basic_tests("unix:/", :socket => file_name)

    connection = Excon::Connection.new({
      :socket           => file_name,
      :nonblock         => false,
      :scheme           => 'unix',
      :ssl_verify_peer  => false
    })
    tests('explicit uri passed to connection') do
      tests('GET /content-length/100').returns(200) do
        response = connection.request(:method => :get, :path => '/content-length/100')
        response[:status]
      end
    end

    expected_formatted_uri = 'unix:///tmp/unicorn.sock/content-length/100'
    tests('unix socket formatted_uri') do
      tests('with no query parameters').returns(expected_formatted_uri) do
        params = connection.data.merge(:method => :get, :path => '/content-length/100')
        Excon::Utils.formatted_uri(params)
      end
      tests('with query parameters as a Hash') do
        query = { :this => 'test', :itworks => 'true' }
        params = connection.data.merge(:method => :get, :query => query, :path => '/content-length/100')
        uri = Excon::Utils.formatted_uri(params)
        query.each do |key, value|
          tests('query parameters exist') do
            uri.include?("#{key}=#{value}")
          end
        end
        tests('uri formatted correctly') do
          uri.start_with?(expected_formatted_uri)
        end
      end
      tests('with query parameters as a Hash') do
        query = "this=test&itworks=true"
        params = connection.data.merge(:method => :get, :query => query, :path => '/content-length/100')
        uri = Excon::Utils.formatted_uri(params)
        tests('query parameters exist') do
          uri.include?(query)
        end
        tests('uri formatted correctly') do
          uri.start_with?(expected_formatted_uri)
        end
      end
    end
  end
end
