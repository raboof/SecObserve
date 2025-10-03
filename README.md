Nix packaging for SecObserve

Currently still with some things hardcoded that shouldn't be.

Usage:

    $ nix run .#frontend
    $ nix run .#manage migrate
    $ nix run .#manage shell
    > import os
    > from application.access_control.models import User
    > User.objects.create_superuser('user', 'email', 'pass')
    $ nix run .#manage register_parsers
    $ nix run .#manage initial_license_load
