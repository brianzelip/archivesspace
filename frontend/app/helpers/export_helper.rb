module ExportHelper
  def csv_response(request_uri, params = {})
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=#{Time.now.to_i}.csv"
    response.headers['Last-Modified'] = Time.now.ctime.to_s
    params['dt'] = 'csv'
    self.response_body = Enumerator.new do |y|
      xml_response(request_uri, params) do |chunk, _percent|
        y << chunk unless chunk.blank?
      end
    end
  end

  def xml_response(request_uri, params = {})
    JSONModel::HTTP.stream(request_uri, params) do |res|
      size = 0
      total = res.header['Content-Length'].to_i
      res.read_body do |chunk|
        size += chunk.size
        percent = total > 0 ? ((size * 100) / total) : 0
        yield chunk, percent
      end
    end
  end
end
