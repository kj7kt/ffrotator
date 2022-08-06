require 'pathname'
require 'open3'

class PathGenerator
  def self.is_exist(path, mode)
    if Pathname(path).exist?
      true
    else
      case mode
      when "dirs"
        puts "ディレクトリが存在しません。"
        false
      when "file"
        puts "ファイルが存在しません。"
        false
      else
        raise StandardError.new("未知のmode: #{mode}")
      end
    end
  end

  def self.get_home(path)
    if path.include?("~")
      path.sub("~", ENV['HOME'])
    else
      path
    end
  end

  def self.in_dir
    loop do
      print "入力元ディレクトリのパスを入力してください: "
      source_dir = gets.chomp.strip
      source_dir = get_home(source_dir)
      is_exist = is_exist(source_dir, "dirs")
      if is_exist
        return Pathname(source_dir)
      end
    end
  end

  def self.in_file
    source_dir = in_dir
    loop do
      print "入力ファイル名を入力してください: "
      source_file_name = gets.chomp.strip
      source_file = Pathname(source_dir / source_file_name)
      is_exist = is_exist(source_file, "file")
      if is_exist
        return Pathname(source_file)
      end
    end
  end

  def self.out_dir
    print "出力先ディレクトリのパスを入力してください: "
    destination_dir = gets.chomp
    destination_dir = get_home(destination_dir)
    is_exist = is_exist(destination_dir, "dirs")
    if is_exist
      Pathname(destination_dir)
    else
      res = confirm("作成しますか？", "default_no")
      if res == "y"
        Pathname(destination_dir).mkpath
        Pathname(destination_dir)
      end
    end
  end

  def self.out_file(source_file)
    destination_dir = out_dir
    loop do
      print "出力ファイル名を入力してください: "
      destination_file_name = gets.chomp.strip
      if File.extname(destination_file_name) == ""
        puts "ファイル名には拡張子が必要です。"
      else
        destination_file = Pathname(destination_dir / destination_file_name)
        if File.extname(destination_file) != File.extname(source_file)
          puts "入力ファイルと出力ファイルの拡張子が異なります。入力ファイルからコピーします。"
          return Pathname(destination_file).sub_ext(File.extname(source_file))
        else
          return destination_file
        end
      end
    end
  end

  def self.format_path(path)
    #パスに含まれるスペースをエスケープする
    if path.include?("\s")
      return path.gsub("\s", "\\\s")
    else
      path
    end
  end
end

class CommandGenerator
  attr_reader :source, :destination, :transpose

  def initialize(source, destination)
    @source = source
    @destination = destination
  end

  def set_transpose

    choice_hash = { "1" => 270, "2" => 180, "3" => 90, "4" => 0 }

    loop do
      puts "時計回りに回転します。回転させたい角度を選び、番号を入力してください"
      print "1. 90° 2. 180° 3. 270° 4. 元に戻す : "
      choice = gets.chomp.strip
      if choice_hash.key?(choice)
        @transpose = choice_hash[choice]
        break
      else
        puts "選択肢から番号で選んでください。"
      end
    end
  end

  def generate
    "ffmpeg -n -i #{@source} -metadata:s:v rotate=#{@transpose} -codec copy #{@destination}"
  end

end

class Main

end

def confirm(question, mode = nil)
  choice_list = %w[y n]
  selections = { nil => "[y/n]: ",
                 "default_yes" => "[Y/n]: ",
                 "default_no" => "[y/N]: " }

  if selections.key?(mode)
    selection = selections[mode]
    if mode == "default_yes" || mode == "default_no"
      choice_list.append("")
    end
  else
    raise StandardError.new("未知のmode: #{mode}")
  end

  loop do
    print question + selection
    user_input = gets.chomp.downcase.strip
    if choice_list.include?(user_input)
      return user_input
    end
  end
end

def rotate(command_to_run)
  prompt = "'#{command_to_run}' を実行します。\nよろしいですか？"
  ans = confirm(prompt, "default_no")
  if ans == "y"
    stdout, stderr, status = Open3.capture3(command_to_run)
    if stderr != nil
      puts stdout
      puts stderr
      puts status
    else
      puts stdout
      puts status
      puts "成功しました！"
    end
  else
    puts "中止します。"
    exit
  end
end

if __FILE__ == $PROGRAM_NAME
  #パスを生成
  source = PathGenerator.in_file
  puts "入力元: #{source}"
  destination = PathGenerator.out_file(source)
  puts "出力先: #{destination}"
  formatted_source = PathGenerator.format_path(source.to_s)
  formatted_destination = PathGenerator.format_path(destination.to_s)

  #コマンドを生成
  command = CommandGenerator.new(formatted_source, formatted_destination)
  command.set_transpose
  command_to_run = command.generate

  #任意の方向に回転
  rotate(command_to_run)
end