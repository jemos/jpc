.. _basic-handshake-section:

Basic Handshake Mechanism
-------------------------

In a performance-focused design, the handshakes are not convenient because they make operations 
take additional clock cycles. However, this project is an educational processor just for my 
learning experience. I could not know upfront if the memory block would be able to provide 
the data at the same clock of the address capture, like a tightly coupled memory. I thought 
that using handshakes would make it easier to support different implementation strategies 
for the blocks and pipeline stages.

.. _basic_handshake:
.. figure:: _images/basic_handshake.png
   :alt: drawing
   :width: 400px
   :align: center

   : Basic handshake mechanism.

As shown in :numref:`basic_handshake`, the basic handshake mechanism with ``ready`` and ``valid`` signals is
inspired by ARM’s AMBA AXI. The flow is the following:

1. The *receiver* asserts ``ready`` to indicate it can accept new data.
2. The *sender* sets data signal (``y_O``) and asserts ``valid`` to indicate that data on the bus is valid.
3. The *receiver* should capture the data at the first clock cycle in which both ``ready`` and ``valid`` are asserted.

Note that the following two scenarios are valid:

1. The ``ready`` is asserted before the ``valid``, and when ``valid`` is asserted, the data transfer occurs;
2. The ``ready`` is asserted in the same clock cycle of ``valid`` and the data transfer occurs.

Thus, the handshake mechanism allows for flexibility in timing, which is useful in designs where the 
timing of data availability is uncertain.

.. note::
   By convention in this project, there is no warranty that the `valid` will remain asserted more than
   one clock cycle. If the receiver does not capture the data in the first clock cycle, it may miss the data.
   Therefore, the receiver, once asserts the ready, should capture the data as soon as it is valid.