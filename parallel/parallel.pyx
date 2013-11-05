# distutils: language = c
# cython: cdivision = True
# cython: boundscheck = False
# cython: wraparound = False
# cython: profile = False

cimport numpy as cnp
import numpy as np
from cython.parallel import parallel, prange
from libc.math cimport sin
cimport openmp
cnp.import_array()
 
ctypedef cnp.float64_t FLOAT_t
ctypedef cnp.intp_t INT_t
ctypedef cnp.ulong_t INDEX_t
ctypedef cnp.uint8_t BOOL_t

cdef class Parent:
    cdef cnp.ndarray numbers
    cdef unsigned int i
    cdef Worker worker1
    cdef Worker worker2
    
    def __init__(Parent self, list numbers):
        self.numbers = <cnp.ndarray[FLOAT_t, ndim=1]> np.array(numbers,dtype=float)
        self.worker1 = Worker()
        self.worker2 = Worker()
    
    cpdef run(Parent self, bint use_parallel):
        cdef unsigned int i
        cdef float best
        cdef int num_threads
        cdef cnp.ndarray[FLOAT_t, ndim=1] numbers = <cnp.ndarray[FLOAT_t, ndim=1]> self.numbers
        cdef FLOAT_t[:] buffer1 = self.numbers[:(len(numbers)//2)]
        buffer_size1 = buffer1.shape[0]
        cdef FLOAT_t[:] buffer2 = self.numbers[(len(numbers)//2):]
        buffer_size2 = buffer2.shape[0]
        
        # Run the workers
        if use_parallel:
            print 'parallel'
            with nogil:
                for i in prange(2, num_threads=2):
                    if i == 0:
                        self.worker1.run(buffer1, buffer_size1)
                    elif i == 1:
                        self.worker2.run(buffer2, buffer_size2)
              
        else:
            print 'serial'
            self.worker1.run(buffer1, buffer_size1)
            self.worker2.run(buffer2, buffer_size2)
        
        #Make sure they both ran
        print self.worker1.output, self.worker2.output
        
        # Choose the worker that had the best solution
        best = min(self.worker1.output, self.worker2.output)
            
        return best
    
cdef class Worker:
    cdef public float output
    def __init__(Worker self):
        self.output = 0.0
    
    cdef void run(Worker self, FLOAT_t[:] numbers, unsigned int buffer_size) nogil:
        cdef unsigned int i
        cdef unsigned int j
        cdef unsigned int n = buffer_size
        cdef FLOAT_t best
        cdef bint first = True
        cdef FLOAT_t value
        for i in range(n):
            for j in range(n):
                value = sin(numbers[i]*numbers[j])
                if first or (value < best):
                    best = value
                    first = False
        self.output = best
        
        
        
    