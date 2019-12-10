require 'json'
require 'ashttp'

class SolrSnapshotter
  def self.log(level, msg)
    if defined?(Log)
      Log.send(level, msg)
    else
      warn("#{level.to_s.upcase}: #{msg}")
    end
  end

  def self.expire_snapshots
    backups = []
    backups_dir = AppConfig[:solr_backup_directory]

    Dir.foreach(backups_dir) do |filename|
      backups << File.join(backups_dir, filename) if filename =~ /^solr\.[0-9]+$/
    end

    victims = backups.sort.reverse.drop(AppConfig[:solr_backup_number_to_keep])

    victims.each do |backup_dir|
      if File.exist?(File.join(backup_dir, 'indexer_state'))
        log(:info, "Expiring old Solr snapshot: #{backup_dir}")
        FileUtils.rm_rf(backup_dir)
      else
        log(:info, "Too cowardly to delete: #{backup_dir}")
      end
    end
  end

  def self.latest_snapshot
    latest = Dir.glob(File.join(AppConfig[:solr_index_directory], 'snapshot.*')).max
  end

  def self.last_snapshot_status
    response = ASHTTP.get_response(URI.join(AppConfig[:solr_url],
                                            '/replication?command=details&wt=json'))

    raise "Problem when getting snapshot details: #{response.body}" if response.code != '200'

    status = JSON.parse(response.body)

    Hash[Array(status.fetch('details', {})['backup']).each_slice(2).to_a]
  end

  def self.snapshot(identifier = nil)
    retries = 5

    retries.times do |i|
      begin
        SolrSnapshotter.do_snapshot(identifier)
        break
      rescue StandardError
        log(:error, "Solr snapshot failed (#{$!}) - attempt #{i}")

        raise "Solr snapshot failed after #{retries} retries: #{$!}" if (i + 1) == retries
      end
    end
  end

  def self.wait_for_snapshot_to_finish(starting_status, starting_snapshot)
    loop do
      raise 'Concurrent snapshot detected.  Bailing out!' if latest_snapshot != starting_snapshot

      status = last_snapshot_status
      break if status != starting_status

      # Wait for the backup status to be updated
      sleep 5
    end
  end

  def self.do_snapshot(identifier = nil)
    identifier ||= Time.now.to_i

    target = File.join(AppConfig[:solr_backup_directory], "solr.#{identifier}")

    FileUtils.mkdir_p(target)

    FileUtils.cp_r(File.join(AppConfig[:data_directory], 'indexer_state'),
                   target)

    begin
      most_recent_status = last_snapshot_status
      most_recent_snapshot = latest_snapshot
      log(:info, "Previous snapshot status: #{most_recent_status}; snapshot: #{most_recent_snapshot}")

      response = ASHTTP.get_response(URI.join(AppConfig[:solr_url],
                                              '/replication?command=backup&numberToKeep=1'))

      raise "Error from Solr: #{response.body}" if response.code != '200'

      # Wait for a new snapshot directory to turn up
      60.times do
        break if most_recent_snapshot != latest_snapshot

        log(:info, 'Waiting for new snapshot directory')
        sleep 1
      end

      raise 'No new snapshot directory appeared' if most_recent_snapshot == latest_snapshot

      wait_for_snapshot_to_finish(most_recent_status, latest_snapshot)
      new_snapshot = latest_snapshot

      FileUtils.mv(new_snapshot, target).inspect
      expire_snapshots
    rescue StandardError
      raise "Solr snapshot failed: #{$!}: #{$@}"
      begin
        FileUtils.rm_rf(target)
      rescue StandardError
      end
    end
  end
end
