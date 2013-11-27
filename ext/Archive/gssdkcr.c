
unsigned char *gssdkcr(
  unsigned char *dst,
  unsigned char *src,
  unsigned char *key) {

    unsigned int    oz,
                    i,
                    keysz,
                    count,
                    old,
                    tmp,
                    randnum;
    unsigned char   *ptr;
    const static char
                    key_default[] =
                    "3b8dd8995f7c40a9a5c5b7dd5b481341";

    randnum = time(NULL);   // something random
    if(!key) key = (unsigned char *)key_default;
    keysz = strlen(key);

    ptr = src;
    old = *ptr;
    tmp = old < 0x4f;
    count = 0;
    for(oz = i = 1; i < 32; i++) {
        count ^= ((((*ptr < old) ^ ((old ^ i) & 1)) ^ (*ptr & 1)) ^ tmp);
        ptr++;
        if(count) {
            if(!(*ptr & 1)) { oz = 0; break; }
        } else {
            if(*ptr & 1) { oz = 0; break; }
        }
    }

    ptr = dst;
    for(i = 0; i < 32; i++, ptr++) {
        if(!oz || !i || (i == 13)) {
            randnum = (randnum * 0x343FD) + 0x269EC3;
            *ptr = (((randnum >> 16) & 0x7fff) % 93) + 33;
            continue;
        } else if((i == 1) || (i == 14)) {
            old = src[i];
        } else {
            old = src[i - 1];
        }
        tmp = (old * i) * 17991;
        old = src[(key[(src[i] + i) % keysz] + (src[i] * i)) & 31];
        *ptr = ((old ^ key[tmp % keysz]) % 93) + 33;
    }
    *ptr = 0x00;

    return(dst);
}
