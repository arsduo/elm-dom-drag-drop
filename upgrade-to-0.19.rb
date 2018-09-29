{
  "Ui.Element" => "Dom.Element",
  "import Dom.Element" => "",
  "Dom.Element.addAttribute" => "Dom.addAttribute",
  "Ui.Modifier.add" => "Dom.addClass",
  "Ui.Modifier.conditional" => "Dom.addClassConditional",
  "import Ui.Modifier" => "",
  "Ui.Attribute.add" => "Dom.addAttribute",
  "import Ui.Attribute" => "",
  "import Dom.Property" => "",
  "import Dom.Attribute" => "",
  "Modular Ui" => "elm-dom",
  "Ui.DragDrop" => "Dom.DragDrop",
  "Ui.Action" => "Dom.addAction",
  # this must come at the end to not rename things like Ui.Modifier => Dom.Modifier
  "import Ui" => "import Dom"
}.each_pair do |find, replace|
  print "Replacing '#{find}' with '#{replace}'..."
  unless system("codemod \"#{find}\" \"#{replace}\" --accept-all --extensions elm,md > /dev/null")
    break
  end
  puts "...done!"
end