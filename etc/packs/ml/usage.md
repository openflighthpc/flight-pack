## ACTIVATION

This pack is accessed using the Flight Environment tool.

To activate the package environment, use the following command:

```
flight env activate conda@ml
```

## ACCESS

Once activated, the machine learning environment can be utilized through Python, e.g.:

```
$ python
Python 3.9.12 (main, Apr  5 2022, 06:56:58)
[GCC 7.5.0] :: Anaconda, Inc. on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import tensorflow as tf
>>> tf.__version__
'2.10.0'
```

## INFORMATION

You can get more information about the configured package environment using the `conda` command, e.g. to display the libraries included within the pack, execute:

```
conda list
```
