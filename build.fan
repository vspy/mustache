using build
class Build : build::BuildPod
{
  new make()
  {
    podName = "mustachefan"
    summary = "Mustache template engine implementation in Fantom"
    srcDirs = [`test/`, `fan/`]
    depends = ["sys 1.0"]
  }
}
