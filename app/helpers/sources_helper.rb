module SourcesHelper
  def write_tmp(file)
    tmpfilename = Dir::Tmpname.create(%w[s- .tmp]) { }
    File.open(tmpfilename, "wb") do |tmpfile|
      tmpfile.write(file.read)
    end
    tmpfilename
  end

  def find_source(size, checksum)
    # TODO: It can't be in a same package
    ActiveStorage::Blob.find_by(byte_size: size, checksum: checksum)
  end
end
