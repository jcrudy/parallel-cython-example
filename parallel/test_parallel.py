from parallel import Parent
import time
data = list(range(20000))
parent = Parent(data)

t0 = time.time()
output = parent.run(False)
t1 = time.time()

print 'Serial Result: %f' % output
print 'Serial Time: %f' % (t1-t0)

t0 = time.time()
output = parent.run(True)
t1 = time.time()

print 'Parallel Result: %f' % output
print 'Parallel Time: %f' % (t1-t0)
