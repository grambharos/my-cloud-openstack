from setuptools import setup, find_packages

setup(
    name='jiraldap',
    version='0.0.1',
    url='https://github.com',
    license='',
    author='gdelaney',
    author_email='gdelaney@ebay.com',
    description='Jira to LDAP/LDIF',
    long_description="Tool to take jira input and create ldap users/groups",
    entry_points={'console_scripts': ['jiraldap=jiraldap.jiraldap:main']},
    classifiers=['Development Status :: 3 - Alpha',
                 'Programming Language :: Python :: 3.6',
                 ],
    install_requires=['ldap3', 'jira'],
    packages=find_packages(),
)
