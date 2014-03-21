function load_page(controller, url) {
    var retry = 4;
    while (retry-- > 0) {
        var success = true;
        controller.open(url);
        try {
            controller.waitForPageLoad(10000);
        } catch(e) {
            success = false;
        }
        if (success) {
            return true;
        }
    }
    controller.open(url);
    return controller.waitForPageLoad(10000);
}

exports.load_page = load_page;
