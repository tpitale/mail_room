require 'spec_helper'
require 'mail_room/delivery/que'

describe MailRoom::Delivery::Que do
  describe '#deliver' do
    let(:mailbox) {build_mailbox({
      delivery_options: {
        database: 'delivery_test',
        username: 'postgres',
        password: '',
        queue: 'default',
        priority: 5,
        job_class: 'ParseMailJob'
      }
    })}

    let(:connection) {stub}
    let(:options) {MailRoom::Delivery::Que::Options.new(mailbox)}

    it 'stores the message in que_jobs table' do
      PG.stubs(:connect).returns(connection)
      connection.stubs(:exec)

      MailRoom::Delivery::Que.new(options).deliver('email')

      expect(PG).to have_received(:connect).with({
        host: 'localhost',
        port: 5432,
        dbname: 'delivery_test',
        user: 'postgres',
        password: ''
      })

      expect(connection).to have_received(:exec).with(
        "INSERT INTO que_jobs (priority, job_class, queue, args) VALUES ($1, $2, $3, $4)",
        [
          5,
          'ParseMailJob',
          'default',
          JSON.dump(['email'])
        ]
      )
    end
  end
end
