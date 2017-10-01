require 'spec_helper'
require 'rspec'
require 'grafana'

RSpec.configure do |config|
  config.mock_with :rspec
end

describe Grafana do

  before do

    config = {
      debug: false,
      grafana: {
        host: 'localhost',
        port: 3000
      }
    }

    @g  = Grafana::Client.new( config )
    @g.login(user: 'admin', password: 'grafana_admin')
  end

  describe 'Instance' do

    it 'login' do
      expect(@g.login(user: 'admin', password: 'grafana_admin')).to be_truthy
      #ping_session).to be_a(Hash)
    end
  end

#   describe 'Admin' do
#
#     it 'admin_settings' do
#       expect(@g.admin_settings()).to be_a(Hash)
#     end
#
#   end
#
#   describe 'Organisation' do
#
#     it 'get current organisation' do
#       puts @g.current_organization
#     end
#
#     it 'getting users from current organisation' do
#       puts @g.current_organization_users
#     end
#
#
# #     it 'check user' do
# #       r = @g.user( 'foo@bar.com')
# #       expect(r).to be_a(Hash)
# #
# #       puts r
# #
# #       status = r.dig('status')
# #       id = r.dig('id')
# #       name = r.dig('name')
# #
# #       expect(status).to be_a(Integer)
# #       expect(id).to be_a(Integer)
# #     end
# #
# #     it 'add user' do
# #
# # #       @g.login(user: 'admin', password: 'grafana_admin')
# #       r = @g.add_user( user_name:'foo', email: 'foo@bar.com', password: 'pass' )
# #       expect(r).to be_a(Hash)
# #
# #       status = r.dig('status')
# #       id = r.dig('id')
# #       message = r.dig('message')
# #
# #       expect(r).to be_a(Hash)
# #       expect(status).to be_a(Integer)
# #       expect(id).to be_a(Integer)
# #
# #     end
#   end
#

  describe 'User' do

    it 'Actual User' do
      r = @g.current_user
      expect(r).to be_a(Hash)
      status  = r.dig('status')

      expect(status).to be_a(Integer)
      expect(status).to be == 200
    end

    it 'Organisations of the actual User' do
      r = @g.current_user_oganizations
      expect(r).to be_a(Hash)
      status  = r.dig('status')

      expect(status).to be_a(Integer)
      expect(status).to be == 200
    end

    it 'import dashboards from directory' do

      r = @g.import_dashboards_from_directory('spec/dashboards')
      expect(r).to be_a(Hash)

#       puts r.find { |x| x.dig('status') }
    end

    it 'Star a dashboard' do
      r = @g.add_dashboard_star( 'QA Graphite Carbon Metrics' )
      expect(r).to be_a(Hash)
      status  = r.dig('status')

      expect(status).to be_a(Integer)
      expect(status).to be == 200
    end

    it 'Unstar a dashboard' do
      r = @g.remove_dashboard_star( 'QA Graphite Carbon Metrics' )
      expect(r).to be_a(Hash)
      status  = r.dig('status')

      expect(status).to be_a(Integer)
      expect(status).to be == 200
    end


    it 'delete dashboard' do
      search = { :tags => 'QA' }
      r = @g.search_dashboards( search )
      expect(r).to be_a(Hash)
      message = r.dig('message')
      expect(message).to be_a(Array)
      expect(message.count).equal?(2)

      message.each do |m|
        title = m.dig('title')
        r = @g.delete_dashboard(title)
        expect(r).to be_a(Hash)
        status  = r.dig('status')
        expect(status).to be == 200
      end

    end
  end


  describe 'Users' do

    it 'All Users' do
      r = @g.all_users
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      message = r.dig('message')

      expect(status).to be_a(Integer)
      expect(status).to be == 200
      expect(message).to be_a(Array)
      expect(message.count).to be >= 1
    end

    it 'Users by Id' do
      r = @g.user_by_id(1)
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      message = r.dig('message')

      expect(status).to be_a(Integer)
      expect(status).to be == 200

      r = @g.user_by_id(2)
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      message = r.dig('message')

      expect(status).to be_a(Integer)
      expect(status).to be == 200
    end

    it 'Users by Name' do
      r = @g.user_by_name( 'admin@localhost' )
      expect(r).to be_a(Hash)

      status  = r.dig('status')
      message = r.dig('message')

      expect(status).to be_a(Integer)
      expect(status).to be == 200
    end

    it 'Search for Users by' do
      r = @g.search_for_users_by( 'isAdmin': true )
      expect(r).to be_a(Array)

      r = @g.search_for_users_by( 'isAdmin': false )
      expect(r).to be_a(FalseClass)
    end

    it 'Get Organisations for user' do

      r = @g.user_organizations('foo@foo-bar.tld')
      expect(r).to be_a(Hash)

      status  = r.dig('status')
      expect(status).to be_a(Integer)
      expect(status).to be == 200
    end

    it 'Update Users' do
      r = @g.update_user(
        user_name: 'foo@foo-bar.tld',
        theme: 'light',
        name: 'spec-test',
        email: 'spec-test@foo-bar.tld'
      )
      expect(r).to be_a(Hash)

      status  = r.dig('status')
      expect(status).to be_a(Integer)
      expect(status).to be == 200

      r = @g.update_user(
        user_name: 'spec-test@foo-bar.tld',
        email: 'foo@foo-bar.tld',
      )
      expect(r).to be_a(Hash)

    end

  end


  describe 'Organisations' do

    it 'Create Organisation' do
      r = @g.create_organisation( name: 'Spec Test' )

      expect(r).to be_a(Hash)

      status  = r.dig('status')
      org_id  = r.dig('orgId')

      expect(status).to be_a(Integer)
      expect(status).to be == 200
      expect(org_id).to be_a(Integer)
    end

    it 'Search all Organisations' do
      r = @g.all_organizations

      expect(r).to be_a(Hash)

      status  = r.dig('status')
      expect(status).to be_a(Integer)
      expect(status).to be == 200
    end

   it 'Get Organisation by Id' do

     r = @g.organization_by_id( 1 )

     expect(r).to be_a(Hash)

     status  = r.dig('status')
     id      = r.dig('id')
     name    = r.dig('name')

     expect(status).to be_a(Integer)
     expect(status).to be == 200
     expect(id).to be_a(Integer)
     expect(name).to be_a(String)
   end

    it 'Get Organisation by Name' do
      r = @g.organization_by_name( 'Spec Test' )

      expect(r).to be_a(Hash)

      status  = r.dig('status')
      id      = r.dig('id')
      name    = r.dig('name')

      expect(status).to be_a(Integer)
      expect(status).to be == 200
      expect(id).to be_a(Integer)
      expect(name).to be_a(String)
      expect(name).to be == 'Spec Test'

    end

    it 'Update Organisation' do

      org = @g.organization_by_name('Spec Test')
      id   = org.dig('id')
      name = org.dig('name')

      r = @g.update_organization( organization: 'Spec Test', name: 'Spec+Test' )
      expect(r).to be_a(Hash)

      status  = r.dig('status')
      expect(status).to be_a(Integer)
      expect(status).to be == 200

      r = @g.update_organization( organization: 'Spec+Test', name: 'Spec Test' )
    end

    it 'Get Users in Organisation' do

      org = @g.organization_by_name('Spec Test')
      id   = org.dig('id')
      name = org.dig('name')

      r = @g.organization_users(id)
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be_a(Integer)
      expect(status).to be == 200
      message = r.dig('message')
      expect(message).to be_a(Array)
      expect(message.size).to be >= 1
    end

    it 'Add User in Organisation' do

      r = @g.add_user_to_organization( organization: 'Spec Test', loginOrEmail: 'foo@foo-bar.tld', role: 'Viewer' )

      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be == 200
    end

    it 'Update Users in Organisation' do
      r = @g.update_organization_user( organization: 'Spec Test', loginOrEmail: 'foo@foo-bar.tld', role: 'Editor' )
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be == 200
    end

    it 'Delete User in Organisation' do
      r = @g.delete_user_from_organization( organization: 'Spec Test', loginOrEmail: 'foo@foo-bar.tld' )
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be == 200
    end

    it 'Delete Organisation' do
      r = @g.delete_organisation( name: 'Spec Test' )
      expect(r).to be_a(Hash)
      status = r.dig('status')
      message = r.dig('message')
      expect(status).to be_a(Integer)
      expect(status).to be == 200
      expect(message).to be_a(String)
    end

  end


  describe 'Dashboard' do

    it 'import dashboards from directory' do

      r = @g.import_dashboards_from_directory('spec/dashboards')
      expect(r).to be_a(Hash)

      puts r.find { |x| x.dig('status') }
    end

    it 'dashboards tags' do
      r = @g.dashboard_tags
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be == 200
    end

    it 'home dashboard' do
      r = @g.home_dashboard
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be == 200
    end

    it 'search tagged dashboards' do
      search = { :tags => 'QA' }
      r = @g.search_dashboards( search )
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be == 200
      message = r.dig('message')
      expect(message).to be_a(Array)
      expect(message.count).equal?(2)
    end

    it 'search starred dashboards' do
      search = { :starred => true }
      r = @g.search_dashboards( search )
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be == 200
      message = r.dig('message')
      expect(message).to be_a(Array)
      expect(message.count).to be == 0
    end

    it 'search dashboards with query' do
      search = { :query => 'QA Graphite Carbon Metrics' }
      r = @g.search_dashboards( search )
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be == 200
      message = r.dig('message')
      expect(message).to be_a(Array)
      expect(message.count).to be == 1
    end

    it 'list dashboard' do
      search = { :query => 'QA Graphite Carbon Metrics' }
      r = @g.search_dashboards( search )
      message = r.dig('message')
      title = message.first.dig('title')
      r = @g.dashboard(title)
      expect(r).to be_a(Hash)
      status  = r.dig('status')
      expect(status).to be == 200
      t = r.dig('dashboard','title')
      expect(t).to be_a(String)
      expect(t).equal?(title)
    end

    it 'delete dashboard' do
      search = { :tags => 'QA' }
      r = @g.search_dashboards( search )
      expect(r).to be_a(Hash)
      message = r.dig('message')
      expect(message).to be_a(Array)
      expect(message.count).equal?(2)

      message.each do |m|
        title = m.dig('title')
        r = @g.delete_dashboard(title)
        expect(r).to be_a(Hash)
        status  = r.dig('status')
        expect(status).to be == 200
      end

    end

  end

end
