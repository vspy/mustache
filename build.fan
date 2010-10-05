using build
class Build : build::BuildPod
{
  new make()
  {
    podName = "mustache"
    summary = "Mustache template engine"
    srcDirs = [`test/`, `fan/`]
    depends = ["sys 1.0"]
  }
}
