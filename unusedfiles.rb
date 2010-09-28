require 'find'

XCODE_PROJECT_FILE = "/project.pbxproj"

class ProjectParser
  
  def initialize
     assetFileTypes = ["wav", "png", "pvr", "caf"]
     sourceFileTypes = ["h", "m", "c", "cpp"]
     @excludeDirs = [".svn", ".git"]
     @assetsPattern = assetFileTypes.join("|")
     @sourcesPattern = sourceFileTypes.join("|")
  end
  
  def allProjectFiles(path)    
    inReferencesSection = false

    projectFiles = []

    file = File.new(path, "r")

    while(line = file.gets)

      if(line =~ /\/\*\s*Begin PBXFileReference/)
        inReferencesSection = true
        next
      elsif(line =~ /\/\*\s*End PBXFileReference/)
        break;
      end

      if(inReferencesSection)
        line = parseLine(line)
        projectFiles << line unless line == nil
      end

    end
    
    return projectFiles          
  end
  
  def parseLine(line)    
    match = line.scan /.*?path\s+=\s+"?([^.]+)\.(#{@assetsPattern})/
    match[0][0] unless match[0] == nil
  end
  
  def unusedFiles(path)    
    filesInProject = allProjectFiles(path+XCODE_PROJECT_FILE)    
    inUse = []
    
    dir = File.dirname(File.expand_path(path));
    
    Find.find(dir) do |file|
      if FileTest.directory?(file)
        if @excludeDirs.include?(File.basename(file))
          Find.prune
        else
          next
        end
      else
        if(file =~ /[^\.]+\.(#{@sourcesPattern})$/)
          data = File.open(file).read

          filesInProject.each do |projectFile|
            projectFileInclude = '"'+projectFile+'"'
            match = data.scan(projectFileInclude)

            if(match && match[0])
              inUse << projectFile
            end
          end
        end
      end
    end
    
    return filesInProject-inUse
  end
  
end

if(!ARGV[0])
  puts "Usage: #{File.basename(__FILE__)} [PROJECT_FILE]"
  exit
end

if(!File.exists?(ARGV[0]))
  puts "#{File.basename(__FILE__)}: #{ARGV[0]}: No such file or directory."
  exit
end

if(!File.exists?(ARGV[0]+XCODE_PROJECT_FILE))
  puts "#{File.basename(__FILE__)}: #{ARGV[0]}: Is not a valid Xcode project."
  exit
end

p = ProjectParser.new
files = p.unusedFiles(ARGV[0])
puts files