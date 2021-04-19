
SUPPORTED_RAILS_VERSIONS = %w[3.0 3.1 3.2 4.0 4.1 4.2 5.0 5.1 5.2 6.0 6.1]

SUPPORTED_RAILS_VERSIONS.each do |rails_ver|
  appraise "rails-#{rails_ver}" do
    gem 'activerecord', "~> #{rails_ver}.x"
    gem 'actionpack',   "~> #{rails_ver}.x"

    if %w[3.0 3.1 3.2].include?(rails_ver)
      gem 'sqlite3'
      #gem 'activerecord-sqlite3-adapter'
    end

  end
end

appraise 'rails-7-edge' do
  gem 'activerecord', git: 'https://github.com/rails/rails', branch: 'main'
  gem 'actionpack',   git: 'https://github.com/rails/rails', branch: 'main'
end

appraise 'datamapper' do
  gem 'datamapper'
  gem 'dm-sqlite-adapter'
end

appraise 'sequel' do
  gem 'sequel'
end



