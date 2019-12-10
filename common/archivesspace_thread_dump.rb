# A class that watches for updates to a status file and generates a Ruby-level
# dump of all running threads, followed by a Java-level dump of all running
# threads.
#
# You can always trigger a JVM-level thread dump by sending a QUIT signal to the
# JVM process, but sometimes these thread dumps can be dashed hard to read.

require 'java'

class ArchivesSpaceThreadDump
  def self.init(status_file_path)
    warn("\n#{self}: Touch the file '#{status_file_path}' to trigger a thread dump")

    Thread.new do
      begin
        watcher = java.nio.file.FileSystems.getDefault.newWatchService

        status_file_path = File.absolute_path(status_file_path)
        dir = java.nio.file.Paths.get(File.dirname(status_file_path))

        dir.register(watcher,
                     java.nio.file.StandardWatchEventKinds::ENTRY_CREATE)

        loop do
          key = watcher.take

          key.poll_events.each do |event|
            # Cast both to Path objects to normalize between '/' and '\\' on win32
            next unless dir.resolve(event.context).to_string == java.nio.file.Paths.get(status_file_path).to_string

            begin
              ArchivesSpaceThreadDump.print_dump
            rescue StandardError
              warn("Problem while printing thread dump: #{$!}")
            end

            File.unlink(status_file_path)
          end

          raise 'Key reset failed' unless key.reset
        end
      rescue StandardError
        warn "Failure in #{self} handler for path #{status_file_path}: #{$!}"
        warn($@)
      end
    end
  end

  def self.print_dump
    warn("[#{Time.now.to_i}] Starting Ruby-level thread dump")
    warn('=' * 72)

    Thread.list.each do |thread|
      warn("\n")
      warn(thread.inspect)
      thread.backtrace.each do |frame|
        warn("  #{frame}")
      end
    end

    warn('')

    warn("[#{Time.now.to_i}] Starting JVM-level thread dump")
    warn('=' * 72)

    java.lang.Thread.all_stack_traces.each do |thread, frames|
      warn("\n")
      warn("\"#{thread.name}\"")
      frames.each do |frame|
        warn("  #{frame}")
      end
    end

    warn('')
    warn('==== End of thread dump ====')
  end
end
