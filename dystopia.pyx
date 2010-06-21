
cdef extern from "stdint.h":
	ctypedef signed long int64_t
	ctypedef unsigned long uint64_t
	ctypedef signed int int32_t
	ctypedef unsigned int uint32_t
	ctypedef signed short int16_t
	ctypedef unsigned short uint16_t
	ctypedef signed char int8_t
	ctypedef unsigned char uint8_t

cdef extern from "dystopia.h":
	enum open_mode:
		IDBOREADER,
		IDBOWRITER,
		IDBOCREAT,
		IDBOTRUNC,
		IDBONOLCK,
		IDBOLCKNB

	enum search_mode:
		IDBSSUBSTR,
		IDBSPREFIX,
		IDBSSUFFIX,
		IDBSFULL,
		IDBSTOKEN,
		IDBSTOKPRE,
		IDBSTOKSUF

	ctypedef struct TCIDB:
		pass

	char *tcidberrmsg(int ecode)

	TCIDB *tcidbnew()
	void tcidbdel(TCIDB *idb)
	int tcidbecode(TCIDB *idb)
	bint tcidbtune(TCIDB *idb, int64_t ernum, int64_t etnum, int64_t iusiz, uint8_t opts)
	bint tcidbsetcache(TCIDB *idb, int64_t icsiz, int32_t lcnum)
	bint tcidbsetfwmmax(TCIDB *idb, uint32_t fwmmax)
	bint tcidbopen(TCIDB *idb, char *path, int omode)
	bint tcidbclose(TCIDB *idb)
	bint tcidbput(TCIDB *idb, int64_t id, char *text)
	bint tcidbout(TCIDB *idb, int64_t id)
	char *tcidbget(TCIDB *idb, int64_t id)
	uint64_t *tcidbsearch(TCIDB *idb, char *word, int smode, int *np)
	uint64_t *tcidbsearch2(TCIDB *idb, char *expr, int *np)
	bint tcidbiterinit(TCIDB *idb)
	uint64_t tcidbiternext(TCIDB *idb)
	bint tcidbsync(TCIDB *idb)
	bint tcidboptimize(TCIDB *idb)
	bint tcidbvanish(TCIDB *idb)
	bint tcidbcopy(TCIDB *idb, char *path)
	char *tcidbpath(TCIDB *idb)
	uint64_t tcidbrnum(TCIDB *idb)
	uint64_t tcidbfsiz(TCIDB *idb)

# Open flags

READER = IDBOREADER
WRITER = IDBOWRITER
CREAT = IDBOCREAT
TRUNC = IDBOTRUNC
NOLCK = IDBONOLCK
LCKNB = IDBOLCKNB

# Search flags

SUBSTR = IDBSSUBSTR
PREFIX = IDBSPREFIX
SUFFIX = IDBSSUFFIX
FULL = IDBSFULL
TOKEN = IDBSTOKEN
TOKPRE = IDBSTOKPRE
TOKSUF = IDBSTOKSUF

# Helper function. Given a pointer to an array of result ID values,
# generate a Python list containing them.

cdef result_list(uint64_t *result, unsigned int result_len):
	pyresult = []

	for i in range(result_len):
		pyresult.append(result[i])

	return pyresult

cdef class database:

	cdef TCIDB *db

	cdef __throw_exception(self):
		errcode = tcidbecode(self.db)
		errmsg = tcidberrmsg(errcode)
		raise Exception(errmsg)

	def __init__(self):
		self.db = tcidbnew()

	def __del__(self):
		tcidbdel(self.db)

	def __len__(self):
		return tcidbrnum(self.db)

	def __iter__(self):
		if not tcidbiterinit(self.db):
			self.__throw_exception()

		# The API only allows for one iterator at a time;
		# the iterator reference is to the DB object.
		# This is rather un-Python-like.

		return self

	# This method is here because the database object acts as its
	# own iterator.

	def __next__(self):
		val = tcidbiternext(self.db)

		if val == 0:
			raise StopIteration()

		return val

	def open(self, filename, mode):
		if not tcidbopen(self.db, filename, mode):
			self.__throw_exception()

	def close(self):
		if not tcidbclose(self.db):
			self.__throw_exception()

	def path(self):
		cdef char *result
		result = tcidbpath(self.db)

		if result == NULL:
			return None
		else:
			return result

	def fsiz(self):
		return tcidbfsiz(self.db)

	def put(self, id, text):
		if not tcidbput(self.db, id, text):
			self.__throw_exception()

	def out(self, id):
		if not tcidbout(self.db, id):
			self.__throw_exception()

	def get(self, id):
		cdef char *text
		text = tcidbget(self.db, id)

		if text == NULL:
			return None
		else:
			return text

	def vanish(self):
		if not tcidbvanish(self.db):
			self.__throw_exception()

	def search(self, word, smode):
		cdef int result_len
		cdef uint64_t *result

		result = tcidbsearch(self.db, word, smode, &result_len)

		if result == NULL:
			self.__throw_exception()

		return result_list(result, result_len)

	def search2(self, expression):
		cdef int result_len
		cdef uint64_t *result

		result = tcidbsearch2(self.db, expression, &result_len)

		if result == NULL:
			self.__throw_exception()

		return result_list(result, result_len)


	def tune(self, ernum, etnum, iusiz, opts):
		if not tcidbtune(self.db, ernum, etnum, iusiz, opts):
			self.__throw_exception()

	def setcache(self, icsiz, lcnum):
		if not tcidbsetcache(self.db, icsiz, lcnum):
			self.__throw_exception()

	def setfwmmax(self, fwmmax):
		if not tcidbsetfwmmax(self.db, fwmmax):
			self.__throw_exception()

	def sync(self):
		if not tcidbsync(self.db):
			self.__throw_exception()

	def optimize(self):
		if not tcidboptimize(self.db):
			self.__throw_exception()

