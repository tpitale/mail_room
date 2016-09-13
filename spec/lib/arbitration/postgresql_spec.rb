require 'spec_helper'
require 'mail_room/arbitration/postgresql'

describe MailRoom::Arbitration::PostgreSQL do
  let(:mailbox) { 
    MailRoom::Mailbox.new(
      arbitration_options: {
        database: 'mail_room_test',
        username: 'postgres',
        password: 'password'
      }
    )
  }
  let(:options) { described_class::Options.new(mailbox) }
  let(:connection) {stub}

  before(:each) do
    PG.stubs(:connect).returns(connection)
  end

  subject { described_class.new(options) }

  it 'connects to postgresql' do
    subject # call subject to run #initialize

    expect(PG).to have_received(:connect).with({
      host: 'localhost',
      port: 5432,
      dbname: 'mail_room_test',
      user: 'postgres',
      password: 'password'
    })
  end

  it 'returns true if an advisory lock for the UID can be obtained' do
    result = stub(:getvalue => 't')
    connection.stubs(:exec_params).returns(result)

    expect(subject.deliver?(88819328181)).to eq(true)

    expect(connection).to have_received(:exec_params).with('SELECT pg_try_advisory_lock($1);', [88819328181])
    expect(result).to have_received(:getvalue).with(0,0)
  end

  it 'returns true if an advisory lock for the UID can be obtained' do
    result = stub(:getvalue => 'f')
    connection.stubs(:exec_params).returns(result)

    expect(subject.deliver?(88819328981)).to eq(false)

    expect(connection).to have_received(:exec_params).with('SELECT pg_try_advisory_lock($1);', [88819328981])
  end
end
