# distutils: language = c
# cython: cdivision = True
# cython: boundscheck = False
# cython: wraparound = False
# cython: profile = False

cimport numpy as cnp
import numpy as np
from cython.parallel import parallel, prange
from libc.math cimport sin
cimport cython
from cpython cimport PyObject
from libc.stdlib cimport malloc, free
cnp.import_array()
 
ctypedef cnp.float64_t FLOAT_t
ctypedef cnp.intp_t INT_t
ctypedef cnp.ulong_t INDEX_t
ctypedef cnp.uint8_t BOOL_t

cdef FLOAT_t MAXfloat64  = np.float64(np.inf)

cdef class Parent:
    cdef FLOAT_t[:] numbers
    cdef unsigned int i
    cdef INDEX_t n_workers
    cdef PyObject **workers
    cdef list ref_workers #Here to maintain references on Python side
    
    def __init__(Parent self, INDEX_t n_workers, list numbers):
        cdef INDEX_t i
        self.n_workers = n_workers
        self.numbers = np.array(numbers,dtype=float)
        self.workers = <PyObject **>malloc(self.n_workers*cython.sizeof(cython.pointer(PyObject)))
        
        #Populate worker pool
        self.ref_workers = []
        for i in range(self.n_workers):
            self.ref_workers.append(Worker())
            self.workers[i] = <PyObject*>self.ref_workers[i]
    
    def __dealloc__(Parent self):
        free(self.workers)
    
    cpdef run(Parent self, bint use_parallel):
        cdef int i
        cdef float best
        cdef int num_threads
        
        # Figure out the buffer start and stop positions
        cdef INT_t * starts = <INT_t *> malloc(self.n_workers * sizeof(INDEX_t))
        cdef INT_t * stops = <INT_t *> malloc(self.n_workers * sizeof(INDEX_t))
        
        step = self.numbers.shape[0] // self.n_workers
        for i in range(self.n_workers):
            starts[i] = i*step
            stops[i] = min((i+1)*step,self.numbers.shape[0])
        
        # Run the workers
        if use_parallel:
            print 'parallel'
            with nogil:
                for i in prange(self.n_workers, num_threads=self.n_workers):
                    (<Worker>self.workers[i]).run(self.numbers, starts[i], stops[i])
        else:
            print 'serial'
            for i in range(self.n_workers):
                (<Worker>self.workers[i]).run(self.numbers, starts[i], stops[i])
        
        #Make sure they both ran
        print [worker.output for worker in self.ref_workers]
        
        # Choose the worker that had the best solution
        best = min([worker.output for worker in self.ref_workers])
        
        free(starts)
        free(stops)
        
        return best
    
cdef class Worker:
    cdef public float output
    def __init__(Worker self):
        self.output = 0.0
    
    cdef void run(Worker self, FLOAT_t[:] numbers, INDEX_t start, INDEX_t stop) nogil:
        cdef unsigned int i
        cdef unsigned int j
        cdef FLOAT_t best
        cdef bint first = True
        cdef FLOAT_t value
        
        best = MAXfloat64
        for i in range(start, stop):
            for j in range(start, stop):
                value = sin(numbers[i]*numbers[j])
                if first or (value < best):
                    best = value
                    first = False
        self.output = best
        
        
        
    
