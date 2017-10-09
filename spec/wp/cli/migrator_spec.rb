require 'spec_helper'

RSpec.describe WP::CLI::Migrator do
  it 'has a version number' do
    expect(WP::CLI::Migrator::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
