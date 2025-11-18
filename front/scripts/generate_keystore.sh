keytool -genkey -noprompt -alias $1 \
 -dname "CN=$1, OU=ID, O=IBM, L=, S=, C=" \
 -keystore $1.keystore \
 -storepass $1 \
 -keypass $1 \
 -validity 9999 \
 -keyalg RSA

keytool -export -rfc -storepass $1 -alias $1 -file $1.certificate.pem -keystore $1.keystore