require "yaml"

namespace :import do
  namespace :winget do
    desc "Empty WinGet account"
    task clear: [:environment] do
      puts User.find_by!(name: "WinGet").packages.delete_all
    end
  end

  desc "Import latest files"
  task winget: [:environment] do
    if Dir.exist?(File.expand_path("~/winget-pkgs"))
      sh "git -C ~/winget-pkgs pull"
    else
      sh "git clone git@github.com:microsoft/winget-pkgs.git ~/winget-pkgs"
    end
    c = 0
    unless user = User.find_by(name: "WinGet")
      puts user = User.create(
        name: "WinGet",
        fullname: "Microsoft WinGet (unofficial)",
        email: "admin@syncbl.com",
        # TODO: Mark this account nologin
        password: "testtest",
        plan: :unlimited,
      )
      Subscription.create(
        user: user,
        start_time: Time.current,
        end_time: Time.current + 100.years,
      )
    end
    files = Dir.glob("../winget-pkgs/manifests/**/*.yaml").sort
    progressbar = ProgressBar.create(total: files.size, title: "WinGet")
    files.each_with_index do |f, i|
      progressbar.increment
      y = YAML.load_file(f)
      next if y["Installers"].nil? || y["PackageName"].nil?

      if i < files.size - 1
        z = YAML.load_file(files[i + 1])
        next if y["PackageName"] == z["PackageName"]
      end
      name = y["PackageName"].gsub(/ ./, "").gsub(/[.:#&]/, "_").gsub("__", "_")
      p = Package::External.find_by(user: user, name: "#{name}") ||
          Package::External.new(
            name: "#{name}",
            user: user,
            version: y["PackageVersion"],
          )
      # TODO: Architecture check for x64
      p.caption = name
      p.short_description = y["ShortDescription"].truncate(MAX_SHORT_DESCRIPTION_LENGTH)
      p.external_url = y["Installers"][0]["InstallerUrl"]
      p.searcheable = true
      if y["InstallerSwitches"]
        p.switches = y["InstallerSwitches"]["Silent"] || y["InstallerSwitches"]["SilentWithProgress"]
      end
      if y["Installers"][0]["InstallerSha256"]
        p.checksum = "sha256:#{y["Installers"][0]["InstallerSha256"]}"
      end
      p.blocked_at = nil
      p.published_at ||= Time.current
      c += 1 if p.save
    end
    puts "#{c} from #{files.size} packages imported"
  end
end
