from setuptools import setup, find_packages

PACKAGE_VERSION = '0.3'

deps = [
        'marionette_harness == 4.0.0',
        'marionette_driver == 2.2.0',
        'mozfile == 1.2',
        'mozinfo == 0.9',
        'mozlog == 3.4',
]

setup(name='tor-browser-tests',
        version=PACKAGE_VERSION,
        description='A collection of Tor Browser tests run with Marionette',
        long_description='A collection of Tor Browser tests run with Marionette',
        classifiers=['Environment :: Console',
            'Intended Audience :: Developers',
            'Natural Language :: English',
            'Operating System :: OS Independent',
            'Programming Language :: Python',
            'Topic :: Software Development :: Libraries :: Python Modules',
            ],
        url='https://gitweb.torproject.org/boklm/tor-browser-bundle-testsuite.git/',
        packages=find_packages(),
        include_package_data=True,
        zip_safe=False,
        install_requires=deps,
        entry_points="""
          [console_scripts]
          tor-browser-tests = tor_browser_tests:cli
        """)
