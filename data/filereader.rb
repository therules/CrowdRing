f = File.new('./new', 'w')
File.open('./india', 'r') do |f1|
    while (line = f1.gets)
        *args = line.split('|')
        info = args.delete_if {|i| i == ""}
        if info.length == 3
            if info[1] != " "
                output = info[0] + ' : [\'' + info[2].strip().tr("\n",'') +'\']' +"\n"
                f.write(output)
            end
        end
    end
end



