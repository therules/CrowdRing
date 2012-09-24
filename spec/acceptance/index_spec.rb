require File.dirname(__FILE__) + '/spec_helper'

describe 'test' do

  before(:each) do
    login
  end

  it 'should show the index page' do
    visit '/'
    page.has_selector? 'menu'
  end
end
