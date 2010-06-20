
cdef extern from "dystopia.h":
	enum openmode:
		IDBOREADER,
		IDBOWRITER,
		IDBOCREAT,
		IDBOTRUNC,
		IDBONOLCK,
		IDBOLCKNB

	ctypedef struct TCIDB:
		pass

	char *tcidberrmsg(int ecode)

	TCIDB *tcidbnew()
	void tcidbdel(TCIDB *idb)
	int tcidbecode(TCIDB *idb)
	bint tcidbtune(TCIDB *idb, int ernum, int etnum, int iusiz, unsigned char opts)
	bint tcidbsetcache(TCIDB *idb, int icsiz, int lcnum)
	bint tcidbsetfwmmax(TCIDB *idb, unsigned int fwmmax)
	bint tcidbopen(TCIDB *idb, char *path, int omode)
	bint tcidbclose(TCIDB *idb)
	bint tcidbput(TCIDB *idb, int id, char *text)
	bint tcidbout(TCIDB *idb, int id)
	char *tcidbget(TCIDB *idb, int id)
	unsigned int *tcidbsearch(TCIDB *idb, char *word, int smode, int *np)
	unsigned int *tcidbsearch2(TCIDB *idb, char *expr, int *np)
	bint tcidbiterinit(TCIDB *idb)
	unsigned int tcidbiternext(TCIDB *idb)
	bint tcidbsync(TCIDB *idb)
	bint tcidboptimize(TCIDB *idb)
	bint tcidbvanish(TCIDB *idb)
	bint tcidbcopy(TCIDB *idb, char *path)
	char *tcidbpath(TCIDB *idb)
	unsigned int tcidbrnum(TCIDB *idb)
	unsigned int tcidbfsiz(TCIDB *idb)

# Open flags

READER = IDBOREADER
WRITER = IDBOWRITER
CREAT = IDBOCREAT
TRUNC = IDBOTRUNC
NOLCK = IDBONOLCK
LCKNB = IDBOLCKNB
	
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

