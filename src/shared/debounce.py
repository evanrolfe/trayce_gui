#  Copyright (c)  2020, salesforce.com, inc.
#  All rights reserved.
#  SPDX-License-Identifier: BSD-3-Clause
#  For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause

import threading

from shared.environment import is_test_env

def debounce(wait_time: float):
    """
    Decorator that will debounce a function so that it is called after wait_time seconds
    If it is called multiple times, will wait for the last call to be debounced and run only this one.
    See the test_debounce.py file for examples
    """

    def decorator(function):
        if is_test_env():
            return function

        def debounced(*args, **kwargs):
            def call_function():
                # this code still works depsite all the typehint complaints, so we ignore them :)
                debounced._timer = None # type:ignore
                return function(*args, **kwargs)

            if debounced._timer is not None: # type:ignore
                debounced._timer.cancel() # type:ignore

            debounced._timer = threading.Timer(wait_time, call_function) # type:ignore
            debounced._timer.start() # type:ignore

        debounced._timer = None # type:ignore
        return debounced

    return decorator
