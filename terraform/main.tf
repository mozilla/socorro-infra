# root module that contains submodules we care about

module "collector" {
    source = "./collector"
}

module "processor" {
    source = "./processor"
}

module "webapp" {
    source = "./webapp"
}
