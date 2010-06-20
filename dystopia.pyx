
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

	def open(self, filename, mode):
		if not tcidbopen(self.db, filename, mode):
			self.__throw_exception()

	def close(self):
		if not tcidbclose(self.db):
			self.__throw_exception()

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

	def tune(self, ernum, etnum, iusiz, opts):
		if not tcidbtune(self.db, ernum, etnum, iusiz, opts):
			self.__throw_exception()

	def setcache(self, icsiz, lcnum):
		if not tcidbsetcache(self.db, icsiz, lcnum):
			self.__throw_exception()

	def setfwmmax(self, fwmmax):
		if not tcidbsetfwmmax(self.db, fwmmax):
			self.__throw_exception()


