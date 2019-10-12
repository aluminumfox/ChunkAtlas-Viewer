/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.centuryglass.mcmap.webserver.security;

import java.security.GeneralSecurityException;
import java.security.InvalidKeyException;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;

/**
 * Abstract basis for RSA key classes.
 */
public abstract class RSAKey
{
    /**
     * Creates a RSAKey object for a particular key value.
     * 
     * @param key  A RSA public or private key value. 
     */
    protected RSAKey (Key key)
    {
        this.key = key;
    }
    
    /**
     * Uses the key to encrypt a byte array, so it can only be decrypted by the
     * other key in the key pair.
     * 
     * @param data                       A data array to encrypt.
     * 
     * @return                           The encrypted value.
     * 
     * @throws InvalidKeyException       If this is not a valid RSA key.
     * 
     * @throws GeneralSecurityException  If the data could not be encrypted
     *                                   properly.
     */
    public byte[] encrypt(byte[] data) throws InvalidKeyException,
            GeneralSecurityException
    {
        return encryptOrDecrypt(data, Cipher.ENCRYPT_MODE);
    }
    
    /**
     * Uses this key to decrypt a byte array that was encrypted with the other
     * key in the key pair.
     * 
     * @param data                       An array of encrypted byte data.
     * 
     * @return                           The decrypted data.
     * 
     * @throws InvalidKeyException       If this is not a valid RSA key.
     * 
     * @throws GeneralSecurityException  If the data could not be decrypted
     *                                   properly.
     */
    public byte[] decrypt(byte[] data) throws InvalidKeyException,
            GeneralSecurityException
    {
        return encryptOrDecrypt(data, Cipher.DECRYPT_MODE);
    }
    
    /**
     * Gets the internal key object used by this RSAKey.
     * 
     * @return  The internal encryption Key object. 
     */
    protected Key getKey()
    {
        return key;
    }
    
    /**
     * Encrypts or decrypts a byte array.
     * 
     * @param data                       The array to transform.
     * 
     * @param mode                       Either Cipher.ENCRYPT_MODE to encrypt
     *                                   the data, or Cipher.DECRYPT_MODE to
     *                                   decrypt the data.
     * 
     * @return                           The transformed data.
     * 
     * @throws InvalidKeyException       If this is not a valid RSA key.
     * 
     * @throws GeneralSecurityException  If the data could not be encrypted or 
     *                                   decrypted properly.
     */
    private byte[] encryptOrDecrypt(byte[] data, int mode)
            throws InvalidKeyException, GeneralSecurityException
    {
        try
        {
            Cipher cipher = Cipher.getInstance("RSA");
            cipher.init(mode, key);
            return cipher.doFinal(data);
        }
        catch (NoSuchAlgorithmException | NoSuchPaddingException e)
        {
            // Getting and using the RSA cipher shouldn't ever fail!
            System.err.println(e.getMessage());
            System.exit(1);
        }
        return null;
    }
    
    private final Key key;
}
