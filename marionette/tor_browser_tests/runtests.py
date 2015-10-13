import os
import sys

from mozlog import structured

from marionette import BaseMarionetteArguments
from marionette import BaseMarionetteTestRunner
from firefox_ui_harness import FirefoxTestCase

def cli(runner_class=BaseMarionetteTestRunner, parser_class=BaseMarionetteArguments):
    parser = parser_class(usage='%(prog)s [options] test_file_or_dir <test_file_or_dir> ...')
    structured.commandline.add_logging_group(parser)
    args = parser.parse_args()
    parser.verify_usage(args)

    logger = structured.commandline.setup_logging(
            args.logger_name, args, {'mach': sys.stdout})
    args.logger = logger
    try:
        runner = runner_class(**vars(args))
        runner.test_handlers = [FirefoxTestCase]
        runner.run_tests(args.tests)
        if runner.failed > 0:
            sys.exit(10)
    except Exception:
        logger.error('Failure during execution test.', exc_info=True)
        sys.exit(1)
